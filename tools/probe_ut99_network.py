"""Inspect a controlled UT server's control channel without joining a match.

The advertised version is diagnostic input, not a claim of game compatibility.
No actor channels are opened and no packages are downloaded.
"""
import argparse
import json
import re
import socket
import time


class Bits:
    def __init__(self, data=None):
        self.bits = [] if data is None else [
            (byte >> bit) & 1 for byte in data for bit in range(8)]
        self.pos = 0
        if data is not None:
            while self.bits and not self.bits[-1]:
                self.bits.pop()
            if not self.bits:
                raise ValueError("Packet has no termination bit")
            self.bits.pop()

    def write(self, value, maximum):
        if not 0 <= value < maximum:
            raise ValueError("Bounded integer overflow")
        current, mask = 0, 1
        while current + mask < maximum:
            bit = bool(value & mask)
            self.bits.append(int(bit))
            if bit:
                current += mask
            mask <<= 1

    def read(self, maximum):
        value, mask = 0, 1
        while value + mask < maximum:
            if self.pos >= len(self.bits):
                raise ValueError("Truncated packet")
            if self.bits[self.pos]:
                value += mask
            self.pos += 1
            mask <<= 1
        return value

    def packet(self):
        bits = self.bits + [1]
        result = bytearray((len(bits) + 7) // 8)
        for i, bit in enumerate(bits):
            result[i // 8] |= bit << (i % 8)
        return bytes(result)


def compact(value):
    """Positive Unreal compact index, used for ANSI string lengths."""
    result = bytearray([value & 63])
    value >>= 6
    if value:
        result[0] |= 64
    while value:
        byte = value & 127
        value >>= 7
        result.append(byte | (128 if value else 0))
    return result


def strings(payload):
    pos = 0
    while pos < len(payload):
        first = payload[pos]
        pos += 1
        length, shift, more = first & 63, 6, first & 64
        while more:
            if pos >= len(payload) or shift > 27:
                raise ValueError("Invalid string length")
            byte = payload[pos]
            pos += 1
            length |= (byte & 127) << shift
            shift += 7
            more = byte & 128
        width = 2 if first & 128 else 1
        end = pos + length * width
        if end > len(payload):
            raise ValueError("Truncated control string")
        yield payload[pos:end].decode("utf-16-le" if width == 2 else "latin1").rstrip("\0")
        pos = end


def probe(host, port, version, timeout):
    messages = []
    packet_id, sequence = 0, 0
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.connect((host, port))
        sock.settimeout(0.3)

        def send(text=None, ack=None):
            nonlocal packet_id, sequence
            out = Bits()
            out.write(packet_id % 16384, 16384)
            packet_id += 1
            if ack is not None:
                out.write(1, 2)
                out.write(ack, 16384)
            if text is not None:
                raw = text.encode("ascii") + b"\0"
                payload = compact(len(raw)) + raw
                out.write(0, 2)  # bunch, not ACK
                opening = sequence == 0
                out.write(int(opening), 2)
                if opening:
                    out.write(1, 2)
                    out.write(0, 2)
                out.write(1, 2)  # reliable
                out.write(0, 1023)  # control channel
                sequence += 1
                out.write(sequence, 1024)
                out.write(1, 8)  # CHTYPE_Control
                out.write(len(payload) * 8, 512 * 8)
                for byte in payload:
                    out.write(byte, 256)
            sock.send(out.packet())

        send(f"HELLO REVISION=0 MINVER=400 VER={version}")
        deadline = time.monotonic() + timeout
        seen = set()
        logged_in = False
        while time.monotonic() < deadline:
            try:
                data = sock.recv(4096)
            except socket.timeout:
                continue
            reader = Bits(data)
            incoming = reader.read(16384)
            send(ack=incoming)
            while reader.pos < len(reader.bits):
                if reader.read(2):
                    reader.read(16384)
                    continue
                control = reader.read(2)
                opening = reader.read(2) if control else 0
                closing = reader.read(2) if control else 0
                reliable = reader.read(2)
                channel = reader.read(1023)
                seq = reader.read(1024) if reliable else 0
                kind = reader.read(8) if reliable or opening else 0
                size = reader.read(4096)
                if size % 8 or reader.pos + size > len(reader.bits):
                    raise ValueError("Unexpected control bunch size")
                payload = bytes(reader.read(256) for _ in range(size // 8))
                if channel or kind not in (0, 1) or (reliable and seq in seen):
                    continue
                seen.add(seq)
                for text in strings(payload):
                    messages.append(text)
                    if text.startswith("CHALLENGE ") and not logged_in:
                        challenge = int(re.search(r"CHALLENGE=(-?\d+)", text)[1])
                        response = ((challenge * 237) ^ 0x93FE92CE ^ (challenge >> 16) ^ (challenge << 16)) & 0xffffffff
                        if response >= 0x80000000:
                            response -= 0x100000000
                        send("NETSPEED 10000")
                        send(f"LOGIN RESPONSE={response} URL=?Name=AndroidNetworkAudit?Class=Botpack.TMale2")
                        logged_in = True
                    if text.startswith(("UPGRADE ", "FAILURE ", "WELCOME ")):
                        return messages
                if closing:
                    return messages
    return messages


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host", help="Server under your control")
    parser.add_argument("--port", type=int, default=7777)
    parser.add_argument("--version", type=int, choices=(400, 432, 436), default=400)
    parser.add_argument("--timeout", type=float, default=5)
    parser.add_argument("--output")
    args = parser.parse_args()
    result = {"host": args.host, "port": args.port, "advertised_version": args.version,
              "scope": "Control-channel diagnostic only; no gameplay compatibility claim",
              "messages": probe(args.host, args.port, args.version, args.timeout)}
    encoded = json.dumps(result, indent=2)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as output:
            output.write(encoded + "\n")
    print(encoded)

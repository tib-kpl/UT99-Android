"""Exercise production controller profiles with small JVM Android input fakes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
package = 'com.ast.unreal' if (root / 'source').is_dir() else 'com.ast.ut99'
source = root / ('source/app' if package.endswith('unreal') else 'app') / 'src/main/java' / package.replace('.', '/')
stubs = {
'android/content/SharedPreferences.java': '''package android.content;
import java.util.*;
public class SharedPreferences {
 public Map<String,Object> data=new HashMap<>();
 public int getInt(String k,int d){return data.containsKey(k)?(Integer)data.get(k):d;}
 public String getString(String k,String d){return data.containsKey(k)?(String)data.get(k):d;}
 public Editor edit(){return new Editor();}
 public class Editor {
  public Editor putInt(String k,int v){data.put(k,v);return this;}
  public Editor putString(String k,String v){data.put(k,v);return this;}
  public Editor clear(){data.clear();return this;} public void apply(){}
 }
}''',
'android/content/Context.java': '''package android.content;
import java.util.*;
public class Context {
 public static final String INPUT_SERVICE="input";
 public Object getSystemService(String s){return null;}
 private Map<String,SharedPreferences> files=new HashMap<>();
 public SharedPreferences getSharedPreferences(String n,int m){if(!files.containsKey(n))files.put(n,new SharedPreferences());return files.get(n);}
}''',
'android/hardware/input/InputManager.java': '''package android.hardware.input;
public class InputManager {
 public interface InputDeviceListener {void onInputDeviceAdded(int id);void onInputDeviceChanged(int id);void onInputDeviceRemoved(int id);}
 public void registerInputDeviceListener(InputDeviceListener listener,Object handler){}
 public void unregisterInputDeviceListener(InputDeviceListener listener){}
}''',
'android/view/InputDevice.java': '''package android.view;
import java.util.*;
public class InputDevice {
 public static final int SOURCE_GAMEPAD=1025,SOURCE_JOYSTICK=16777232;
 public static Map<Integer,InputDevice> devices=new LinkedHashMap<>();
 public int id,sources=SOURCE_GAMEPAD; public String descriptor; public boolean virtual;
 public InputDevice(int id,String descriptor){this.id=id;this.descriptor=descriptor;devices.put(id,this);}
 public static InputDevice getDevice(int id){return devices.get(id);}
 public static int[] getDeviceIds(){return devices.keySet().stream().mapToInt(i->i).toArray();}
 public int getSources(){return sources;} public boolean isVirtual(){return virtual;}
 public String getDescriptor(){return descriptor;} public String getName(){return descriptor;}
}''',
'android/view/KeyEvent.java': '''package android.view;
public class KeyEvent {
 public static final int ACTION_DOWN=0,ACTION_UP=1;
 int action,key,repeat,device,scan,flags,source,meta; long down,time;
 public KeyEvent(long d,long t,int a,int k,int r,int m,int id,int s,int f,int src){down=d;time=t;action=a;key=k;repeat=r;meta=m;device=id;scan=s;flags=f;source=src;}
 public static KeyEvent changeAction(KeyEvent e,int a){return new KeyEvent(e.down,e.time,a,e.key,e.repeat,e.meta,e.device,e.scan,e.flags,e.source);}
 public int getAction(){return action;} public int getKeyCode(){return key;} public int getRepeatCount(){return repeat;}
 public int getDeviceId(){return device;} public int getScanCode(){return scan;} public int getFlags(){return flags;}
 public int getSource(){return source;} public int getMetaState(){return meta;} public long getDownTime(){return down;}
 public long getEventTime(){return time;} public InputDevice getDevice(){return InputDevice.getDevice(device);}
}''',
}
menu = '''package PACKAGE;
import java.util.*;
final class GameSettingsMenu {
 interface Choice {void changed(int index);}
 Map<String,Choice> choices=new HashMap<>(); Map<String,Runnable> buttons=new HashMap<>(); int refreshed;
 void section(String s){} void note(String s){} void refresh(){refreshed++;}
 void button(String s,Runnable r){buttons.put(s,r);}
 void choice(String s,String[] values,int initial,int def,Choice c){choices.put(s,c);}
 void confirm(String s,String accept,Runnable r){r.run();}
}'''
test = '''package PACKAGE;
import android.content.*; import android.view.*; import java.util.*;
public class ControllerMappingTest {
 static void check(boolean ok,String label){if(!ok)throw new AssertionError(label);}
 static KeyEvent key(int device,int key,int action){return new KeyEvent(1,2,action,key,0,0,device,0,0,InputDevice.SOURCE_GAMEPAD);}
 public static void main(String[] args){
  Context context=new Context(); InputDevice first=new InputDevice(1,"Odin"); new InputDevice(2,"USB");
  ArrayList<String> sent=new ArrayList<>();
  ControllerMapping[] mapper=new ControllerMapping[1];
  mapper[0]=new ControllerMapping(context,e->{check(!mapper[0].key(e),"relay recursion bypass");sent.add(e.getKeyCode()+":"+e.getAction());check(e.getScanCode()==0,"normalized scan code");});
  SharedPreferences profile=context.getSharedPreferences("controller_Odin",0);
  check(mapper[0].key(key(1,96,0)),"A handled"); mapper[0].key(key(1,96,1));
  check(sent.toString().equals("[96:0, 96:1]"),"identity default"); sent.clear();
  profile.edit().putInt("button_96",97).apply();
  mapper[0].key(key(1,96,0)); profile.edit().putInt("button_96",98).apply(); mapper[0].key(key(1,96,1));
  check(sent.toString().equals("[97:0, 97:1]"),"release uses press-time mapping"); sent.clear();
  mapper[0].key(key(1,96,0)); mapper[0].key(key(1,96,0)); mapper[0].reset(); mapper[0].key(key(1,96,1));
  check(sent.toString().equals("[98:0, 98:1]"),"score, repeat and lifecycle release"); sent.clear();
  profile.edit().putInt("button_96",97).apply();
  mapper[0].key(key(1,96,0)); mapper[0].key(key(1,97,0)); mapper[0].key(key(1,96,1));
  check(sent.size()==1,"merged physical buttons keep target held"); mapper[0].key(key(1,97,1));
  check(sent.toString().equals("[97:0, 97:1]"),"merged target releases once"); sent.clear();
  profile.edit().putInt("button_96",0).apply(); mapper[0].key(key(1,96,0));mapper[0].key(key(1,96,1));
  check(sent.isEmpty(),"disabled consumes both edges");
  profile.edit().putInt("button_96",108).apply(); mapper[0].key(key(1,96,0));mapper[0].reset();
  check(sent.toString().equals("[96:0, 96:1]"),"invalid stored targets cannot steal Start"); sent.clear();
  check(!mapper[0].key(key(1,108,0))&&!mapper[0].key(key(1,109,0)),"reserved chord");
  check(!mapper[0].key(key(1,104,0))&&!mapper[0].key(key(1,19,0)),"triggers and dpad unchanged");
  first.virtual=true;check(!mapper[0].key(key(1,96,0)),"virtual touch untouched");first.virtual=false;
  first.sources=257;check(!mapper[0].key(key(1,96,0)),"keyboard untouched");first.sources=InputDevice.SOURCE_GAMEPAD;
  profile.edit().putInt("button_96",98).apply();
  InputDevice.devices.remove(1); new InputDevice(7,"Odin");
  mapper[0].key(key(7,96,0)); mapper[0].key(key(2,96,0)); mapper[0].reset();
  check(sent.contains("98:0")&&sent.contains("96:0"),"stable per-device profiles across reconnect"); sent.clear();
  mapper[0].key(new KeyEvent(1,2,0,0,0,0,7,317,0,InputDevice.SOURCE_GAMEPAD));mapper[0].reset();
  check(sent.toString().equals("[106:0, 106:1]"),"unknown key normalized by scan code");sent.clear();
  mapper[0].key(key(7,96,0)); InputDevice.devices.remove(7); mapper[0].key(key(2,96,0));mapper[0].reset();
  check(sent.toString().equals("[98:0, 98:1, 96:0, 96:1]"),"disconnect clears stale output");
  sent.clear();mapper[0].key(key(2,96,0));mapper[0].onInputDeviceRemoved(2);
  check(sent.toString().equals("[96:0, 96:1]"),"unplug immediately releases without further input");
  new InputDevice(9,"Odin");
  context.getSharedPreferences("controller_selection",0).edit().putString("descriptor","Odin").apply();
  GameSettingsMenu menu=new GameSettingsMenu();ControllerMapping.page(context,menu,true,false);
  menu.choices.get("A / \\u00d7").changed(9);
  check(profile.getInt("button_96",96)==0,"UI edits selected controller profile");
  menu.buttons.get("Reset this controller").run();check(profile.getInt("button_96",96)==96,"per-controller reset");
  check(context.getSharedPreferences("controller_USB",0).data.isEmpty(),"other profiles preserved");
  for(int button:ControllerBindings.BUTTONS)check(ControllerBindings.validated(button,-5)==button,"invalid fallback");
  System.out.println("Controller mapping: all input, persistence, device isolation and UI checks passed");
 }
}'''

suffix = '.exe' if os.name == 'nt' else ''
def executable(name):
    return str(Path(os.environ['JAVA_HOME']) / 'bin' / (name + suffix)) if os.environ.get('JAVA_HOME') else shutil.which(name)

with tempfile.TemporaryDirectory(prefix='controller-mapping-') as temp:
    folder=Path(temp)
    files=[]
    for name, content in stubs.items():
        file=folder/name; file.parent.mkdir(parents=True,exist_ok=True);file.write_text(content,encoding='utf-8');files.append(str(file))
    for name,content in [('GameSettingsMenu.java',menu),('ControllerMappingTest.java',test)]:
        file=folder/name;file.write_text(content.replace('PACKAGE',package),encoding='utf-8');files.append(str(file))
    files.extend(str(source/name) for name in ['ControllerMapping.java','ControllerBindings.java'])
    subprocess.run([executable('javac'),'-encoding','UTF-8','-d',temp,*files],check=True)
    subprocess.run([executable('java'),'-cp',temp,package+'.ControllerMappingTest'],check=True)

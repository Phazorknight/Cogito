using Godot;
using Godot.Collections;

namespace NathanHoad
{
  public partial class InputHelper : Node
  {
    public delegate void DeviceChangedEventHandler(string device, int deviceIndex);
    public delegate void KeyboardInputChangedEventHandler(string action, InputEvent input);
    public delegate void JoypadInputChangedEventHandler(string action, InputEvent input);
    public delegate void JoypadChangedEventHandler(int deviceIndex, bool isConnected);

    public static DeviceChangedEventHandler? DeviceChanged;
    public static KeyboardInputChangedEventHandler? KeyboardInputChanged;
    public static JoypadInputChangedEventHandler? JoypadInputChanged;
    public static JoypadChangedEventHandler? JoypadChanged;


    public const string DEVICE_KEYBOARD = "keyboard";
    public const string DEVICE_XBOX_CONTROLLER = "xbox";
    public const string DEVICE_SWITCH_CONTROLLER = "switch";
    public const string DEVICE_PLAYSTATION_CONTROLLER = "playstation";
    public const string DEVICE_STEAMDECK_CONTROLLER = "steamdeck";
    public const string DEVICE_GENERIC = "generic";

    public const string SUB_DEVICE_XBOX_ONE_CONTROLLER = "xbox_one";
    public const string SUB_DEVICE_XBOX_SERIES_CONTROLLER = "xbox_series";
    public const string SUB_DEVICE_PLAYSTATION3_CONTROLLER = "playstation3";
    public const string SUB_DEVICE_PLAYSTATION4_CONTROLLER = "playstation4";
    public const string SUB_DEVICE_PLAYSTATION5_CONTROLLER = "playstation5";
    public const string SUB_DEVICE_SWITCH_JOYCON_LEFT_CONTROLLER = "switch_left_joycon";
    public const string SUB_DEVICE_SWITCH_JOYCON_RIGHT_CONTROLLER = "switch_right_joycon";


    private static Node instance;
    public static Node Instance
    {
      get
      {
        if (instance == null)
        {
          instance = (Node)Engine.GetSingleton("InputHelper");
          instance.Connect("device_changed", Callable.From((string device, int deviceIndex) => DeviceChanged?.Invoke(device, deviceIndex)));
          instance.Connect("keyboard_input_changed", Callable.From((string action, InputEvent input) => KeyboardInputChanged?.Invoke(action, input)));
          instance.Connect("joypad_input_changed", Callable.From((string action, InputEvent input) => JoypadInputChanged?.Invoke(action, input)));
          instance.Connect("joypad_changed", Callable.From((int deviceIndex, bool isConnected) => JoypadChanged?.Invoke(deviceIndex, isConnected)));
        }
        return instance;
      }
    }


    public static string Device
    {
      get => (string)Instance.Get("device");
    }


    public static int DeviceIndex
    {
      get => (int)Instance.Get("device_index");
    }


    public static string LastKnownJoypadDevice
    {
      get => (string)Instance.Get("last_known_joypad_device");
    }


    public static string LastKnownJoypadIndex
    {
      get => (string)Instance.Get("last_known_joypad_index");
    }


    public static float Deadzone
    {
      get => (float)Instance.Get("deadzone");
      set => Instance.Set("deadzone", value);
    }


    public static int MouseMotionThreshold
    {
      get => (int)Instance.Get("mouse_motion_threshold");
      set => Instance.Set("mouse_motion_threshold", value);
    }


    public static string GetSimplifiedDeviceName(string rawName)
    {
      return (string)Instance.Call("get_simplified_device_name", rawName);
    }


    public static string GetDeviceFromEvent(InputEvent @event)
    {
      return (string)Instance.Call("get_device_from_event", @event);
    }


    public static int GetDeviceIndexFromEvent(InputEvent @event)
    {
      return (int)Instance.Call("get_device_index_from_event", @event);
    }


    public static bool HasJoypad()
    {
      return (bool)Instance.Call("has_joypad");
    }


    public static string GuessDeviceName()
    {
      return (string)Instance.Call("guess_device_name");
    }


    public static void ResetAllActions()
    {
      Instance.Call("reset_all_actions");
    }


    public static void SetKeyboardOrJoypadInputForAction(string action, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("set_keyboard_or_joypad_input_for_action", action, input, swapIfTaken);
    }


    public static InputEvent GetKeyboardOrJoypadInputForAction(string action, InputEvent input, bool swapIfTaken = true)
    {
      return (InputEvent)Instance.Call("get_keyboard_or_joypad_input_for_action", action, input, swapIfTaken);
    }


    public static Array<InputEvent> GetKeyboardOrJoypadInputsForAction(string action)
    {
      return (Array<InputEvent>)Instance.Call("get_keyboard_or_joypad_inputs_for_action", action);
    }


    public static string GetLabelForInput(InputEvent input)
    {
      return (string)Instance.Call("get_label_for_input", input);
    }


    public static string SerializeInputsForActions(Array<string> actions = null)
    {
      if (actions == null)
      {
        actions = new Array<string>();
      }
      return (string)Instance.Call("serialize_inputs_for_actions", actions);
    }


    public static void DeserializeInputsForActions(string serializedInputs)
    {
      Instance.Call("deserialize_inputs_for_actions", serializedInputs);
    }


    #region Keyboard/Mouse

    public static Array<InputEvent> GetKeyboardInputsForAction(string action)
    {
      return (Array<InputEvent>)Instance.Call("get_keyboard_inputs_for_action", action);
    }


    public static InputEvent GetKeyboardInputForAction(string action)
    {
      return (InputEvent)Instance.Call("get_keyboard_input_for_action", action);
    }


    public static void SetKeyboardInputForAction(string action, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("set_keyboard_input_for_action", action, input, swapIfTaken);
    }


    public static void ReplaceKeyboardInputForAction(string action, InputEvent currentInput, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("replace_keyboard_input_for_action", action, currentInput, input, swapIfTaken);
    }


    public static void ReplaceKeyboardInputAtIndex(string action, int index, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("replace_keyboard_input_at_index", action, index, input, swapIfTaken);
    }

    #endregion


    #region Joypad

    public static Array<InputEvent> GetJoypadInputsForAction(string action)
    {
      return (Array<InputEvent>)Instance.Call("get_joypad_inputs_for_action", action);
    }


    public static InputEvent GetJoypadInputForAction(string action)
    {
      return (InputEvent)Instance.Call("get_joypad_input_for_action", action);
    }


    public static void SetJoypadInputForAction(string action, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("set_joypad_input_for_action", action, input, swapIfTaken);
    }


    public static void ReplaceJoypadInputForAction(string action, InputEvent currentInput, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("replace_joypad_input_for_action", action, currentInput, input, swapIfTaken);
    }


    public static void ReplaceJoypadInputAtIndex(string action, int index, InputEvent input, bool swapIfTaken = true)
    {
      Instance.Call("replace_joypad_input_at_index", action, index, input, swapIfTaken);
    }


    public static void RumbleSmall(int targetDevice = 0)
    {
      Instance.Call("rumble_small", targetDevice);
    }


    public static void RumbleMedium(int targetDevice = 0)
    {
      Instance.Call("rumble_medium", targetDevice);
    }


    public static void RumbleLarge(int targetDevice = 0)
    {
      Instance.Call("rumble_large", targetDevice);
    }


    public static void StartRumbleSmall(int targetDevice = 0)
    {
      Instance.Call("start_rumble_small", targetDevice);
    }


    public static void StartRumbleMedium(int targetDevice = 0)
    {
      Instance.Call("start_rumble_medium", targetDevice);
    }


    public static void StartRumbleLarge(int targetDevice = 0)
    {
      Instance.Call("start_rumble_large", targetDevice);
    }


    public static void StopRumble(int targetDevice = 0)
    {
      Instance.Call("stop_rumble", targetDevice);
    }

    #endregion
  }
}

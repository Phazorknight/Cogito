namespace GodotStateCharts;
using Godot;

public class StateChartSerializer
{
    private static readonly GodotObject Wrapped = GD.Load("res://addons/godot_state_charts/state_chart_serializer.gd");

    
    /// <summary>
    /// Serializes the given state chart and returns a serialized object that
    /// can be stored as part of a saved game.
    /// </summary>
    /// <param name="stateChart">the state chart to serialize</param>
    /// <returns>a resource containing the serialized state</returns>
    public static SerializedStateChart Serialize(StateChart stateChart)
    {
        return SerializedStateChart.Of(Wrapped.Call("serialize", stateChart.Wrapped).As<Resource>());
    }
    
    /// <summary>
    /// Deserializes the given serialized state chart into the given state chart. Returns a set of
    /// error messages. If the serialized state chart was no longer compatible with the current state
    /// chart, nothing will happen. The operation is successful when the returned array is empty.
    /// </summary>
    public static string[] Deserialize(SerializedStateChart serializedStateChart, StateChart stateChart)
    {
        var variant = Wrapped.Call("deserialize",  serializedStateChart.Wrapped, stateChart.Wrapped);
        return variant.AsStringArray();
    }
    
}


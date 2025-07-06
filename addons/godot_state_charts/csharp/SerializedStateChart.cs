// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using System;
    using Godot;

    /// <summary>
    /// C# wrapper for the SerializedStateChart Godot resource.
    /// </summary>
    public class SerializedStateChart : ResourceWrapper
    {
        private SerializedStateChart(Resource wrapped) : base(wrapped) { }

        public static SerializedStateChart Of(Resource resource)
        {
            if (resource.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("serialized_state_chart.gd"))
            {
                throw new ArgumentException("Given resource is not a SerializedStateChart.");
            }
            return new SerializedStateChart(resource);
        }

        public int Version
        {
            get => Wrapped.Get("version").AsInt32();
            set => Wrapped.Set("version", value);
        }
        
        public string Name
        {
            get => Wrapped.Get("name").AsString();
            set => Wrapped.Set("name", value);
        }

        public Godot.Collections.Dictionary ExpressionProperties
        {
            get => Wrapped.Get("expression_properties").AsGodotDictionary();
            set => Wrapped.Set("expression_properties", value);
        }

        public Godot.Collections.Array QueuedEvents
        {
            get => Wrapped.Get("queued_events").AsGodotArray();
            set => Wrapped.Set("queued_events", value);
        }

        public bool PropertyChangePending
        {
            get => Wrapped.Get("property_change_pending").AsBool();
            set => Wrapped.Set("property_change_pending", value);
        }

        public bool StateChangePending
        {
            get => Wrapped.Get("state_change_pending").AsBool();
            set => Wrapped.Set("state_change_pending", value);
        }

        public bool LockedDown
        {
            get => Wrapped.Get("locked_down").AsBool();
            set => Wrapped.Set("locked_down", value);
        }

        public Godot.Collections.Array QueuedTransitions
        {
            get => Wrapped.Get("queued_transitions").AsGodotArray();
            set => Wrapped.Set("queued_transitions", value);
        }

        public bool TransitionsProcessingActive
        {
            get => Wrapped.Get("transitions_processing_active").AsBool();
            set => Wrapped.Set("transitions_processing_active", value);
        }

        public SerializedStateChartState State
        {
            get
            {
                var stateRes = Wrapped.Get("state").As<Resource>();
                return stateRes != null ? SerializedStateChartState.Of(stateRes) : null;
            }
            set => Wrapped.Set("state", value?.Wrapped);
        }
    }
}


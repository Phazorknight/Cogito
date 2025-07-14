using System;
using System.Collections.Generic;
using Godot;

namespace GodotStateCharts
{
    /// <summary>
    /// C# wrapper for the SerializedStateChartState Godot resource.
    /// </summary>
    public class SerializedStateChartState : ResourceWrapper
    {
        private SerializedStateChartState(Resource wrapped) : base(wrapped)
        {
        }

        public static SerializedStateChartState Of(Resource resource)
        {
            if (resource.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("serialized_state_chart_state.gd"))
            {
                throw new ArgumentException("Given resource is not a SerializedStateChartState.");
            }

            return new SerializedStateChartState(resource);
        }

        public string Name
        {
            get => Wrapped.Get("name").AsString();
            set => Wrapped.Set("name", value);
        }

        public int StateType
        {
            get => Wrapped.Get("state_type").AsInt32();
            set => Wrapped.Set("state_type", value);
        }

        public bool Active
        {
            get => Wrapped.Get("active").AsBool();
            set => Wrapped.Set("active", value);
        }

        public string PendingTransitionName
        {
            get => Wrapped.Get("pending_transition_name").AsString();
            set => Wrapped.Set("pending_transition_name", value);
        }

        public float PendingTransitionRemainingDelay
        {
            get => Wrapped.Get("pending_transition_remaining_delay").AsSingle();
            set => Wrapped.Set("pending_transition_remaining_delay", value);
        }

        public float PendingTransitionInitialDelay
        {
            get => Wrapped.Get("pending_transition_initial_delay").AsSingle();
            set => Wrapped.Set("pending_transition_initial_delay", value);
        }

        public List<SerializedStateChartState> Children
        {
            get
            {
                var wrappedChildren = Wrapped.Get("children").AsGodotArray();
                var result = new List<SerializedStateChartState>();
                // ReSharper disable once LoopCanBeConvertedToQuery
                foreach (var item in wrappedChildren)
                {
                    result.Add(Of(item.As<Resource>()));
                }

                return result;
            }
            set
            {
                var wrappedChildren = new Godot.Collections.Array();
                foreach (var child in value)
                {
                    wrappedChildren.Add(child.Wrapped);
                }

                Wrapped.Set("children", wrappedChildren);
            }
        }
    }
}

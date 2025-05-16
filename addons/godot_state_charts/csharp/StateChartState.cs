// ReSharper disable once CheckNamespace

namespace GodotStateCharts
{
    using Godot;
    using System;

    /// <summary>
    /// A wrapper around the state node that allows interacting with it from C#.
    /// </summary>
    public class StateChartState : NodeWrapper
    {
        /// <summary>
        /// Called when the state is entered.
        /// </summary>
        public event Action StateEntered
        {
            add => Wrapped.Connect(SignalName.StateEntered, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateEntered, Callable.From(value));
        }
        
        /// <summary>
        ///  Called when the state is exited.
        /// </summary>
        public event Action StateExited
        {
            add => Wrapped.Connect(SignalName.StateExited, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateExited, Callable.From(value));
        }
        
        /// <summary>
        /// Called when the state receives an event. Only called if the state is active.
        /// </summary>
        public event Action<StringName> EventReceived
        {
            add => Wrapped.Connect(SignalName.EventReceived, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.EventReceived, Callable.From(value));
        }

        /// <summary>
        /// Called when the state is processing.
        /// </summary>
        public event Action<float> StateProcessing
        {
            add => Wrapped.Connect(SignalName.StateProcessing, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateProcessing, Callable.From(value));
        }
        
        /// <summary>
        /// Called when the state is physics processing.
        /// </summary>
        public event Action<float> StatePhysicsProcessing
        {
            add => Wrapped.Connect(SignalName.StatePhysicsProcessing, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StatePhysicsProcessing, Callable.From(value));
        }
        
        /// <summary>
        /// Called when the state chart <code>Step</code> function is called.
        /// </summary>
        public event Action StateStepped
        {
            add => Wrapped.Connect(SignalName.StateStepped, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateStepped, Callable.From(value));
        }
        
        /// <summary>
        /// Called when the state is receiving input.
        /// </summary>
        public event Action<InputEvent> StateInput
        {
            add => Wrapped.Connect(SignalName.StateInput, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateInput, Callable.From(value));
        }
        
        /// <summary>
        /// Called when the state is receiving unhandled input.
        /// </summary>
        public event Action<InputEvent> StateUnhandledInput
        {
            add => Wrapped.Connect(SignalName.StateUnhandledInput, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.StateUnhandledInput, Callable.From(value));
        }
        
        /// <summary>
        /// Called every frame while a delayed transition is pending for this state.
        /// Returns the initial delay and the remaining delay of the transition.
        /// </summary>
        public event Action<float,float> TransitionPending
        {
            add => Wrapped.Connect(SignalName.TransitionPending, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.TransitionPending, Callable.From(value));
        }
        

        protected StateChartState(Node wrapped) : base(wrapped) {}
       

        /// <summary>
        /// Creates a wrapper object around the given node and verifies that the node
        /// is actually a state. The wrapper object can then be used to interact
        /// with the state chart from C#.
        /// </summary>
        /// <param name="state">the node that is the state</param>
        /// <returns>a State wrapper.</returns>
        /// <throws>ArgumentException if the node is not a state.</throws>
        public static StateChartState Of(Node state)
        {
            if (state.GetScript().As<Script>() is not GDScript gdScript ||
                !gdScript.ResourcePath.EndsWith("state.gd"))
            {
                throw new ArgumentException("Given node is not a state.");
            }

            return new StateChartState(state);
        }

        /// <summary>
        /// Returns true if this state is currently active.
        /// </summary>
        public bool Active => Wrapped.Get("active").As<bool>();

      
        public class SignalName : Godot.Node.SignalName
        {

            /// <see cref="StateChartState.StateEntered"/>
            public static readonly StringName StateEntered = "state_entered";

            /// <see cref="StateChartState.StateExited"/>
            public static readonly StringName StateExited = "state_exited";

            /// <see cref="StateChartState.EventReceived"/>
            public static readonly StringName EventReceived = "event_received";
    
            /// <see cref="StateChartState.StateProcessing"/>
            public static readonly StringName StateProcessing = "state_processing";
    
            /// <see cref="StateChartState.StatePhysicsProcessing"/>
            public static readonly StringName StatePhysicsProcessing = "state_physics_processing";
            
            /// <see cref="StateChartState.StateStepped"/>
            public static readonly StringName StateStepped = "state_stepped";

            /// <see cref="StateChartState.StateInput"/>
            public static readonly StringName StateInput = "state_input";
                
            /// <see cref="StateChartState.StateUnhandledInput"/>
            public static readonly StringName StateUnhandledInput = "state_unhandled_input";
            
            /// <see cref="StateChartState.TransitionPending"/>
            public static readonly StringName TransitionPending = "transition_pending";
            
        }
    }
}

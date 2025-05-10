

// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using System;
    using Godot;
    
    /// <summary>
    /// Wrapper around the compound state node.
    /// </summary>
    public class CompoundState : StateChartState
    {
        /// <summary>
        /// Called when a child state is entered.
        /// </summary>
        public event Action ChildStateEntered
        {
            add => Wrapped.Connect(SignalName.ChildStateEntered, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.ChildStateEntered, Callable.From(value));
        }
        
        /// <summary>
        /// Called when a child state is exited.
        /// </summary>
        public event Action ChildStateExited
        {
            add => Wrapped.Connect(SignalName.ChildStateExited, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.ChildStateExited, Callable.From(value));
        }
        
        private CompoundState(Node wrapped) : base(wrapped)
        {
        }

        /// <summary>
        /// Creates a wrapper object around the given node and verifies that the node
        /// is actually a compound state. The wrapper object can then be used to interact
        /// with the compound state chart from C#.
        /// </summary>
        /// <param name="state">the node that is the state</param>
        /// <returns>a State wrapper.</returns>
        /// <throws>ArgumentException if the node is not a state.</throws>
        public new static CompoundState Of(Node state)
        {
            if (state.GetScript().As<Script>() is not GDScript gdScript ||
                !gdScript.ResourcePath.EndsWith("compound_state.gd"))
            {
                throw new ArgumentException("Given node is not a compound state.");
            }

            return new CompoundState(state);
        }

        public new class SignalName : StateChartState.SignalName
        {
  
            /// <see cref="CompoundState.ChildStateEntered"/>
            public static readonly StringName ChildStateEntered = "child_state_entered";

            /// <see cref="CompoundState.ChildStateExited"/>
            public static readonly StringName ChildStateExited = "child_state_exited";

        }
    }
}

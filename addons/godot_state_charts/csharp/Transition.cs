using System;

namespace GodotStateCharts
{
    using Godot;

    /// <summary>
    /// A transition between two states. 
    /// </summary>
    public class Transition : NodeWrapper {
        
        /// <summary>
        /// Called when the transition is taken.
        /// </summary>
        public event Action Taken {
            add => Wrapped.Connect(SignalName.Taken, Callable.From(value));
            remove => Wrapped.Disconnect(SignalName.Taken, Callable.From(value));
        }
        
        private Transition(Node transition) : base(transition) {}
        
        public static Transition Of(Node transition) {
            if (transition.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("transition.gd"))
            {
                throw new ArgumentException("Given node is not a transition.");
            }
            return new Transition(transition);
        }
        
        /// <summary>
        /// Takes the transition. The transition will be taken immediately by 
        /// default, even if it has a delay. If you want to wait for the delay
        /// to pass, you can set the immediately parameter to false.
        /// </summary>
        public void Take(bool immediately = true) {
            Call(MethodName.Take, immediately);
        }
        
        
        public class SignalName : Godot.Node.SignalName
        {
            /// <see cref="Transition.Taken"/>
            public static readonly StringName Taken = "taken";
        }

        public class MethodName : Godot.Node.MethodName
        {
            /// <see cref="Transition.Take"/>
            public static readonly StringName Take = "take";
        }
    }
}

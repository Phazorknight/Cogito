// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using Godot;
    using System;

    /// <summary>
    /// Wrapper around the state chart debugger node.
    /// </summary>
    public class StateChartDebugger : NodeWrapper
    {
        private StateChartDebugger(Node wrapped) : base(wrapped) {}

        /// <summary>
        ///  Creates a wrapper object around the given node and verifies that the node
        /// is actually a state chart debugger. The wrapper object can then be used to interact
        /// with the state chart debugger from C#.
        /// </summary>
        /// <param name="stateChartDebugger">the node that is the state chart debugger</param>
        /// <returns>a StateChartDebugger wrapper.</returns>
        /// <throws>ArgumentException if the node is not a state chart debugger.</throws>
        public static StateChartDebugger Of(Node stateChartDebugger)
        {
            if (stateChartDebugger.GetScript().As<Script>() is not GDScript gdScript
                || !gdScript.ResourcePath.EndsWith("state_chart_debugger.gd"))
            {
                throw new ArgumentException("Given node is not a state chart debugger.");
            }

            return new StateChartDebugger(stateChartDebugger);
        }

        /// <summary>
        /// Sets the node that the state chart debugger should debug.
        /// </summary>
        /// <param name="node">the the node that should be debugged. Can be a state chart or any
        /// node above a state chart. The debugger will automatically pick the first state chart
        /// node below the given one.</param>
        public void DebugNode(Node node)
        {
            Call(MethodName.DebugNode, node);
        }
        
        /// <summary>
        /// Adds a history entry to the history output.
        /// </summary>
        /// <param name="text">the text to add</param>
        public void AddHistoryEntry(string text)
        {
            Call(MethodName.AddHistoryEntry, text);
        }
        
        public class MethodName : Node.MethodName
        {
            /// <summary>
            /// Sets the node that the state chart debugger should debug.
            /// </summary>
            public static readonly string DebugNode = "debug_node";
            /// <summary>
            ///  Adds a history entry to the history output.
            /// </summary>
            public static readonly string AddHistoryEntry = "add_history_entry";
        }
    }
}

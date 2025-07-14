// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using Godot;
    
    /// <summary>
    /// Base class for all wrapper classes. Provides some common functionality. Not to be used directly.
    /// </summary>
    public abstract class NodeWrapper
    {
        /// <summary>
        /// The wrapped node.
        /// </summary>
        protected internal readonly Node Wrapped;

        protected NodeWrapper(Node wrapped)
        {
            Wrapped = wrapped;
        }
          
        /// <summary>
        /// Allows to connect to signals on the wrapped node.
        /// </summary>
        /// <param name="signal"></param>
        /// <param name="method"></param>
        /// <param name="flags"></param>
        public Error Connect(StringName signal, Callable method, uint flags = 0u)
        {
            return Wrapped.Connect(signal, method, flags);
        }
        
        
        /// <summary>
        /// Allows to call methods on the wrapped node deferred.
        /// </summary>
        public Variant CallDeferred(string method, params Variant[] args)
        {
            return Wrapped.CallDeferred(method, args);
        }
        
        /// <summary>
        /// Allows to call methods on the wrapped node.
        /// </summary>
        public Variant Call(string method, params Variant[] args)
        {
            return Wrapped.Call(method, args);
        }
    }
}

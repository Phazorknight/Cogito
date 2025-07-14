// ReSharper disable once CheckNamespace
namespace GodotStateCharts
{
    using Godot;
    
    /// <summary>
    /// Base class for all wrapper classes for Godot Resource types. Provides common functionality. Not to be used directly.
    /// </summary>
    public abstract class ResourceWrapper
    {
        /// <summary>
        /// The wrapped resource. Useful for you need to access the underlying resource directly,
        /// e.g. for serialization.
        /// </summary>
        public readonly Resource Wrapped;

        protected ResourceWrapper(Resource wrapped)
        {
            Wrapped = wrapped;
        }

        /// <summary>
        /// Allows to call methods on the wrapped resource deferred.
        /// </summary>
        public Variant CallDeferred(string method, params Variant[] args)
        {
            return Wrapped.CallDeferred(method, args);
        }

        /// <summary>
        /// Allows to call methods on the wrapped resource.
        /// </summary>
        public Variant Call(string method, params Variant[] args)
        {
            return Wrapped.Call(method, args);
        }
    }
}


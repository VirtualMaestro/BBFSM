/**
 * User: VirtualMaestro
 * Date: 29.06.13
 * Time: 15:03
 */
package bb_fsm
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 *
	 */
	public class BBFSMEntity implements BBIFSMEntity
	{
		internal var i_fsm:BBFSM;
		internal var i_agent:Object;

		private var _classRef:Class;
		private var _id:int = 0;
		private var _rid:Boolean = false;

		protected var shared:Boolean = false;

		/**
		 * Enable/disable invoke of 'update' method. By default 'false'
		 */
		public var updateEnable:Boolean = false;

		/**
		 */
		public function BBFSMEntity()
		{
			_id = BBUniqueId.getId();
		}

		/**
		 * When agent goes in to current state/transition.
		 */
		public function enter():void
		{
		}

		/**
		 * When agent goes out from current state/transition.
		 */
		public function exit():void
		{
		}

		/**
		 * Invokes every tick (enter frame) in case if fsm invokes own 'update' method.
		 */
		public function update(p_deltaTime:int):void
		{
		}

		/**
		 * Returns instance of fsm that owns current instance of entity.
		 */
		public function get fsm():BBFSM
		{
			return i_fsm;
		}

		/**
		 * Returns agent of current instance.
		 */
		public function get agent():Object
		{
			return i_agent;
		}

		/**
		 * Returns class of current instance.
		 */
		public function getClass():Class
		{
			if (_classRef == null) _classRef = getDefinitionByName(getQualifiedClassName(this)) as Class;
			return _classRef;
		}

		/**
		 * Determines if current instance shared.
		 * E.g. if possible to use one instance (e.g.) state for several agents.
		 * By default 'false'.
		 * There is property 'shared', it is possible to set it in instances/children.
		 */
		public function get isShared():Boolean
		{
			return shared;
		}

		/**
		 * Returns unique number of current instance.
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Checks if entity disposed.
		 */
		[Inline]
		final public function get isDisposed():Boolean
		{
			return i_agent == null;
		}

		/**
		 * Removes current instance, but it is possible to re-use it (it is stored in cache).
		 */
		public function dispose():void
		{
			if (!isDisposed)
			{
				if (!_rid) i_fsm.addEntityToPool(this);

				i_agent = null;
				i_fsm = null;
			}
		}

		/**
		 * Completely removes current instance without possibility to re-use it.
		 * If need to override it in children don't forget to invoke super method.
		 */
		public function rid():void
		{
			_rid = true;

			dispose();
		}
	}
}

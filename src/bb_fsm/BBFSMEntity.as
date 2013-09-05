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
		 */
		public function enter():void
		{
		}

		/**
		 */
		public function exit():void
		{
		}

		/**
		 */
		public function update(p_deltaTime:int):void
		{
		}

		/**
		 */
		public function get fsm():BBFSM
		{
			return i_fsm;
		}

		/**
		 */
		public function get agent():Object
		{
			return i_agent;
		}

		/**
		 */
		public function getClass():Class
		{
			if (_classRef == null) _classRef = getDefinitionByName(getQualifiedClassName(this)) as Class;
			return _classRef;
		}

		/**
		 */
		public function get isShared():Boolean
		{
			return shared;
		}

		/**
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Checks if entity disposed.
		 */
		public function get isDisposed():Boolean
		{
			return i_agent == null;
		}

		/**
		 */
		public function dispose():void
		{
			if (!isDisposed)
			{
				i_agent = null;
				i_fsm.addEntityToPool(this);
				i_fsm = null;
			}
		}

		/**
		 */
		public function rid():void
		{
			// override in children
		}
	}
}

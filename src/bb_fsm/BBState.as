/**
 * User: VirtualMaestro
 * Date: 25.06.13
 * Time: 18:13
 */
package bb_fsm
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	/**
	 * Represents of state for state machine.
	 */
	public class BBState implements BBIFSMEntity
	{
		internal var i_agent:Object;
		internal var i_fsm:BBFSM;

		private var _classRef:Class;

		protected var shared:Boolean = false;

		/**
		 */
		public function BBState()
		{
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
		public function update(p_deltaTime:Number):void
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
		protected function get agent():Object
		{
			return i_agent;
		}

		/**
		 */
		public function dispose():void
		{
			i_agent = null;
			i_fsm.addEntityToPool(this);
			i_fsm = null;
		}

		/**
		 */
		final public function getClass():Class
		{
			if (_classRef == null) _classRef = getDefinitionByName(getQualifiedClassName(this)) as Class;
			return _classRef;
		}

		/**
		 */
		final public function get isShared():Boolean
		{
			return shared;
		}
	}
}

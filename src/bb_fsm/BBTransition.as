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
	 * Represents of transition between states.
	 */
	public class BBTransition implements BBIFSMEntity
	{
		internal var i_fsm:BBFSM;
		internal var i_onCompleteCallback:Function;

		internal var i_stateFromClass:Class;
		internal var i_stateToClass:Class;

		private var _stateFrom:BBState;
		private var _stateTo:BBState;
		private var _classRef:Class;

		protected var shared:Boolean = false;

		/**
		 */
		public function BBTransition(p_stateFromClass:Class, p_stateToClass:Class)
		{
			i_stateFromClass = p_stateFromClass;
			i_stateToClass = p_stateToClass;

			CONFIG::debug
			{
				BBAssert.isTrue((i_stateFromClass != i_stateToClass), "stateFrom and stateTo can't be the same class", "constructor BBTransition");
				BBAssert.isTrue((i_stateFromClass != null), "stateFromClass can't be null", "constructor BBTransition");
				BBAssert.isTrue((i_stateToClass != null), "stateToClass can't be null", "constructor BBTransition");
			}
		}

		/**
		 */
		internal function setStates(p_stateFrom:BBState, p_stateTo:BBState):void
		{
			_stateFrom = p_stateFrom;
			_stateTo = p_stateTo;
		}

		/**
		 */
		public function enter():void
		{
			// Need to override in children
//			exit();
		}

		/**
		 */
		public function exit():void
		{
			if (i_onCompleteCallback != null) i_onCompleteCallback();
		}

		/**
		 */
		public function update(p_deltaTime:Number):void
		{
			// override in children
		}

		/**
		 */
		public function get stateFrom():BBState
		{
			return _stateFrom;
		}

		/**
		 */
		public function get stateTo():BBState
		{
			return _stateTo;
		}

		/**
		 */
		public function get fsm():BBFSM
		{
			return i_fsm;
		}

		/**
		 * If during transition was invoked this method there is nest scenario:
		 * - onCompleteCallback is nullify;
		 * - transition is disposed;
		 * - stateTo is disposed;
		 * - exit method won't invoke;
		 */
		internal function interrupt():void
		{
			if (_stateTo) _stateTo.dispose();
			dispose();
		}

		/**
		 */
		public function dispose():void
		{
			i_onCompleteCallback = null;
			i_stateFromClass = null;
			i_stateToClass = null;
			_stateFrom = null;
			_stateTo = null;
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

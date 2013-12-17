/**
 * User: VirtualMaestro
 * Date: 25.06.13
 * Time: 18:13
 */
package bb_fsm
{
	import bb.signals.BBSignal;

	/**
	 * Represents of transition between states.
	 */
	public class BBTransition extends BBFSMEntity
	{
		private var _onBegin:BBSignal;
		private var _onComplete:BBSignal;

		internal var i_onCompleteCallback:Function;

		internal var i_stateFromClass:Class;
		internal var i_stateToClass:Class;

		private var _stateFrom:BBState;
		private var _stateTo:BBState;

		/**
		 */
		public function BBTransition(p_stateFromClass:Class, p_stateToClass:Class)
		{
			super();

			i_stateFromClass = p_stateFromClass;
			i_stateToClass = p_stateToClass;

			CONFIG::debug
			{
				BBAssert.isTrue((i_stateFromClass != i_stateToClass), "stateFrom and stateTo can't be the same class", "constructor BBTransition");
				BBAssert.isTrue((i_stateFromClass != null), "stateFromClass can't be null", "constructor BBTransition");
				BBAssert.isTrue((i_stateToClass != null), "stateToClass can't be null", "constructor BBTransition");
			}

			_onBegin = BBSignal.get(this, true);
			_onComplete = BBSignal.get(this, true);
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
		override public function exit():void
		{
			if (i_onCompleteCallback != null) i_onCompleteCallback();
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
		 * Signal dispatches when transition begin.
		 */
		final public function get onBegin():BBSignal
		{
			return _onBegin;
		}

		/**
		 * Signal dispatches when transition complete.
		 */
		final public function get onComplete():BBSignal
		{
			return _onComplete;
		}

		/**
		 * Removes current instance, but it is possible to re-use it (it is stored in cache).
		 */
		override public function dispose():void
		{
			if (!isDisposed)
			{
				i_onCompleteCallback = null;
				i_stateFromClass = null;
				i_stateToClass = null;
				_stateFrom = null;
				_stateTo = null;

				super.dispose();
			}
		}

		/**
		 * Completely removes current instance without possibility to re-use it.
		 * If need to override it in children don't forget to invoke super method.
		 */
		override public function rid():void
		{
			super.rid();

			if (_onBegin) _onBegin.dispose();
			_onBegin = null;

			if (_onComplete) _onComplete.dispose();
			_onComplete = null;
		}
	}
}

/**
 * User: VirtualMaestro
 * Date: 29.06.13
 * Time: 14:27
 */
package bb_fsm
{
	import bb.signals.BBSignal;

	/**
	 * Represents of series of transitions.
	 */
	public class BBSequenceTransitions extends BBFSMEntity
	{
		private var _onComplete:BBSignal;

		//
		private var _stack:BBStack;
		private var _current:BBTransitionItem;
		private var _timeBeforeTransitionBegin:int = 0;
		private var _transitionComplete:Boolean = false;

		/**
		 */
		public function BBSequenceTransitions()
		{
			super();

			_stack = new BBStack();
			_onComplete = BBSignal.get(this, true);
		}

		/**
		 * Adds transition to sequence.
		 * p_delayBeforeNext - delaying milliseconds before start new transition.
		 */
		public function addTransition(p_transition:Class, p_delayBeforeNext:int = 0):void
		{
			_stack.push(new BBTransitionItem(p_transition, p_delayBeforeNext));
		}

		/**
		 */
		override public function enter():void
		{
			setTransition(next());
		}

		/**
		 */
		private function setTransition(p_item:BBTransitionItem):void
		{
			_current = p_item;
			_timeBeforeTransitionBegin = _current.delay;
			_transitionComplete = false;

			fsm.onTransitionCreated.add(transitionCreated, true);
			fsm.doTransition(_current.transition);
		}

		/**
		 */
		private function transitionCreated(p_signal:BBSignal):void
		{
			(p_signal.params as BBTransition).onComplete.add(transitionComplete);
		}

		/**
		 */
		private function transitionComplete(p_signal:BBSignal):void
		{
			_current = next();
			_transitionComplete = true;

			if (_current == null) // if it was last transition
			{
				_onComplete.dispatch();
				exit();
				dispose();
			}
		}

		/**
		 * Skip all transitions and start doing last transition.
		 */
		public function skip():void
		{
			var numTransitions:int = _stack.size;
			for (var i:int = numTransitions - 1; i > 1; i--)
			{
				next().dispose();
			}

			setTransition(next());
		}

		/**
		 * Returns next transition in stack.
		 */
		[Inline]
		private function next():BBTransitionItem
		{
			return _stack.pop() as BBTransitionItem;
		}

		/**
		 */
		override public function update(p_deltaTime:int):void
		{
			if (_transitionComplete)
			{
				_timeBeforeTransitionBegin -= p_deltaTime;
				if (_timeBeforeTransitionBegin <= 0)
				{
					setTransition(_current);
				}
			}
		}

		/**
		 */
		public function interrupt():void
		{
			_onComplete.dispatch();
			dispose();
		}

		/**
		 * Dispatches when all transitions are completed.
		 */
		public function get onComplete():BBSignal
		{
			return _onComplete;
		}

		/**
		 */
		private function clear():void
		{
			var numTransitions:int = _stack.size;
			if (numTransitions > 0)
			{
				for (var i:int = numTransitions - 1; i >= 0; i--)
				{
					next().dispose();
				}
			}
		}

		/**
		 */
		override public function dispose():void
		{
			if (!isDisposed)
			{
				clear();
				_current = null;
				_timeBeforeTransitionBegin = 0;
				_transitionComplete = false;

				super.dispose();
			}
		}

		/**
		 */
		override public function rid():void
		{
			if (_onComplete) _onComplete.dispose();
			_onComplete = null;
		}
	}
}
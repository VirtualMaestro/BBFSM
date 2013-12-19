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
		private var _transitionsList:Vector.<BBTransitionItem>;
		private var _numTransitions:int = 0;
		private var _currentTransitionIndex:int = 0;
		private var _currentItem:BBTransitionItem;
		private var _currentTransition:BBTransition;

		private var _timeBeforeTransitionBegin:int = 0;
		private var _transitionComplete:Boolean = false;

		internal var i_completeCallback:Function;

		/**
		 */
		public function BBSequenceTransitions()
		{
			super();

			_transitionsList = new <BBTransitionItem>[];
		}

		/**
		 *
		 */
		protected function addTransitions(p_transitionList:Array, p_delayBeforeNext:int = 0):void
		{
			var len:int = p_transitionList.length;

			for (var i:int = 0; i < len; i++)
			{
				addTransition(p_transitionList[i], p_delayBeforeNext);
			}
		}

		/**
		 * Adds transition to sequence.
		 * p_delayBeforeNext - delaying milliseconds before start new transition.
		 */
		protected function addTransition(p_transition:Class, p_delayBeforeNext:int = 0):void
		{
			_transitionsList[_numTransitions++] = new BBTransitionItem(p_transition, p_delayBeforeNext);
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
			_currentItem = p_item;
			_timeBeforeTransitionBegin = _currentItem.delay;
			_transitionComplete = false;

			_currentTransition = fsm.doTransition(_currentItem.transition);

			if (_currentTransition) _currentTransition.onComplete.add(transitionComplete);
			else interrupt();
		}

		/**
		 */
		private function transitionComplete(p_signal:BBSignal):void
		{
			_currentTransition = null;
			_currentItem = next();
			_transitionComplete = true;

			if (_currentItem == null) // if it was last transition
			{
				exit();

				i_completeCallback();
				if (_onComplete) _onComplete.dispatch();

				dispose();
			}
		}

		/**
		 * Skip all transitions and start doing last transition.
		 */
		public function skipAll():void
		{
			_currentTransitionIndex = _numTransitions - 1;
			if (_currentTransition) _currentTransition.exit();
		}

		/**
		 * Starts do transition from given number.
		 * If you have 5 transitions the last transition index is 4.
		 */
		protected function setTransitionByIndex(p_transitionIndex:uint):void
		{
			_currentTransitionIndex = p_transitionIndex < _numTransitions ? p_transitionIndex : _numTransitions - 1;
			if (_currentTransition) _currentTransition.exit();
		}

		/**
		 * Returns next transition in stack.
		 */
		[Inline]
		final private function next():BBTransitionItem
		{
			return _currentTransitionIndex < _numTransitions ? _transitionsList[_currentTransitionIndex++] : null;
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
					setTransition(_currentItem);
				}
			}
		}

		/**
		 */
		public function interrupt():void
		{
			if (_currentTransition) _currentTransition.interrupt();
			i_completeCallback();
			_transitionComplete = true;

			dispose();
		}

		/**
		 * Dispatches when all transitions are completed.
		 */
		public function get onComplete():BBSignal
		{
			if (_onComplete == null) _onComplete = BBSignal.get(this, true);
			return _onComplete;
		}

		/**
		 */
		override public function dispose():void
		{
			if (!isDisposed)
			{
				if (!_transitionComplete) interrupt();

				_currentTransitionIndex = 0;
				_currentItem = null;
				_timeBeforeTransitionBegin = 0;
				_transitionComplete = false;
				_currentTransition = null;
				i_completeCallback = null;

				super.dispose();
			}
		}

		/**
		 * Dispose and clear all transition items in transition list and remove list at all.
		 */
		private function clear():void
		{
			var numTransitions:int = _transitionsList.length;
			for (var i:int = 0; i < numTransitions; i++)
			{
				_transitionsList[i].dispose();
				_transitionsList[i] = null;
			}

			_transitionsList.length = 0;
			_transitionsList = null;
		}

		/**
		 */
		override public function rid():void
		{
			super.rid();

			clear();

			if (_onComplete) _onComplete.dispose();
			_onComplete = null;
		}
	}
}
/**
 * User: VirtualMaestro
 * Date: 25.06.13
 * Time: 18:11
 */
package bb_fsm
{
	import bb.signals.BBSignal;

	import flash.utils.Dictionary;

	/**
	 * Class of finite state machine.
	 */
	final public class BBFSM implements BBIDisposable
	{
		// Dispatches when state was created but not switched or makes enter phase
		private var _onStateCreated:BBSignal;

		// Dispatches when transition was created but not started and makes enter phase
		private var _onTransitionCreated:BBSignal;

		private var _agent:Object;
		private var _stack:BBStack;

		private var _currentState:BBState;
		private var _currentTransition:BBTransition;
		private var _sequenceTransitions:BBSequenceTransitions;

		private var _defaultState:Class;
		private var _isStack:Boolean = false;
		private var _id:int = 0;

		private var _isTransitioning:Boolean = false;

		/**
		 */
		public function BBFSM(p_agent:Object, p_defaultState:Class, p_isStack:Boolean = false)
		{
			CONFIG::debug
			{
				BBAssert.isTrue(p_agent != null, "parameter 'agent' can't be null", "constructor BBFSM");
				BBAssert.isTrue(p_defaultState != null, "parameter 'p_defaultState' can't be null", "constructor BBFSM");
			}

			_id = BBUniqueId.getId();

			initFSM(p_agent, p_defaultState, p_isStack);
		}

		/**
		 */
		[Inline]
		private function initFSM(p_agent:Object, p_defaultState:Class, p_isStack:Boolean = false):void
		{
			_agent = p_agent;
			_defaultState = p_defaultState;
			_currentState = getState(p_defaultState);

			if (p_isStack)
			{
				_isStack = true;
				_stack = new BBStack();
				_stack.push(_currentState);
			}

			_currentState.enter();
		}

		/**
		 */
		public function changeState(p_stateClass:Class, p_force:Boolean = false):void
		{
			if (!interruptTransitions(p_force)) return;

			//
			var newState:BBState = getState(p_stateClass);

			if (_isStack)
			{
				_stack.push(_currentState);
				switchStates(newState);
			}
			else switchStates(newState, true);
		}

		/**
		 */
		[Inline]
		private function initEntity(p_entity:BBFSMEntity):void
		{
			p_entity.i_agent = _agent;
			p_entity.i_fsm = this;
		}

		/**
		 * Switched states - old state makes exit, new state enter.
		 * Returns previous state.
		 */
		[Inline]
		private function switchStates(p_newState:BBState, p_disposePreviousState:Boolean = false):void
		{
			if (_onStateCreated) _onStateCreated.dispatch(p_newState);

			var prevState:BBState = _currentState;
			_currentState.exit();
			_currentState = p_newState;
			_currentState.enter();

			if (p_disposePreviousState) prevState.dispose();
		}

		/**
		 * Try to interrupt transitions if they are exist.
		 * Returns 'true' if was interrupted (doesn't matter if  transitions really interrupted or they just absent),
		 * and 'false' if transitions can't be interrupted.
		 */
		[Inline]
		private function interruptTransitions(p_forceInterrupt:Boolean = false):Boolean
		{
			var isInterrupted:Boolean = true;

			if (isTransitioning)
			{
				if (!p_forceInterrupt) isInterrupted = false;
				else
				{
					_currentTransition.interrupt();
					_isTransitioning = false;
				}
			}

			return isInterrupted;
		}

		/**
		 */
		public function doTransition(p_transitionClass:Class, p_force:Boolean = false):void
		{
			if (!interruptTransitions(p_force)) return;

			//
			var transition:BBTransition = getTransition(p_transitionClass);
			if (_onTransitionCreated) _onTransitionCreated.dispatch(transition);

			// stateFrom class is not the same as currentState, so need to change states before transition
			if (_currentState.getClass() != transition.i_stateFromClass)
			{
				changeState(transition.i_stateFromClass);
			}

			//
			var nextState:BBState = new transition.i_stateToClass();
			initEntity(nextState);
			transition.setStates(_currentState, nextState);
			transition.i_onCompleteCallback = transitionCompleteCallback;
			_currentTransition = transition;
			_isTransitioning = true;
			_currentTransition.onBegin.dispatch();
			_currentTransition.enter();
		}

		/**
		 */
		private function transitionCompleteCallback():void
		{
			switchStates(_currentTransition.stateTo, !_isStack);

			_isTransitioning = false;
			_currentTransition.onComplete.dispatch();
			_currentTransition.dispose();
			_currentTransition = null;
		}

		/**
		 */
		public function doSequenceTransitions(p_sequenceTransitions:Class, p_force:Boolean = false):void
		{
			if (!interruptTransitions(p_force)) return;

			_sequenceTransitions = getSequenceTransitions(p_sequenceTransitions);
			_sequenceTransitions.onComplete.add(sequenceTransitionsComplete);
			_sequenceTransitions.enter();
		}

		/**
		 */
		[Inline]
		private function sequenceTransitionsComplete(p_signal:BBSignal):void
		{
			_sequenceTransitions = null;
		}

		/**
		 */
		public function skipSequenceTransitions():void
		{
			if (_sequenceTransitions) _sequenceTransitions.skip();
		}

		/**
		 * Checks whether or not the transition.
		 */
		[Inline]
		final public function get isTransitioning():Boolean
		{
			return _isTransitioning;
		}

		/**
		 */
		public function update(p_deltaTime:Number):void
		{
			_currentState.update(p_deltaTime);
			if (_currentTransition) _currentTransition.update(p_deltaTime);
			if (_sequenceTransitions) _sequenceTransitions.update(p_deltaTime);
		}

		/**
		 * Put state on top of stack.
		 */
		public function push(p_stateClass:Class):void
		{
			CONFIG::debug
			{
				BBAssert.isTrue(_isStack, "you can't use 'push' method if state machine isn't marked as stack", "BBFSM.push");
			}

			changeState(p_stateClass);
		}

		/**
		 * Removes state on top of stack.
		 * Stack should contains at least one state, so you can't remove last state.
		 */
		public function pop():void
		{
			CONFIG::debug
			{
				BBAssert.isTrue(_isStack, "you can't use 'pop' method if state machine isn't marked as stack", "BBFSM.pop");
			}

			if (_stack.size > 0) switchStates(_stack.pop() as BBState, true);
		}

		/**
		 * FSM entity like state and transition adds to appropriate pool.
		 */
		[Inline]
		final internal function addEntityToPool(p_entity:BBIFSMEntity):void
		{
			putEntity(p_entity);
		}

		[Inline]
		private function getState(p_stateClass:Class):BBState
		{
			var state:BBState = getEntity(p_stateClass) as BBState;
			initEntity(state);

			return state;
		}

		[Inline]
		private function getTransition(p_transitionClass:Class):BBTransition
		{
			var transition:BBTransition = getEntity(p_transitionClass) as BBTransition;
			initEntity(transition);

			return transition;
		}

		[Inline]
		private function getSequenceTransitions(p_sequenceTransitionClass:Class):BBSequenceTransitions
		{
			var sequenceTransition:BBSequenceTransitions = getEntity(p_sequenceTransitionClass) as BBSequenceTransitions;
			initEntity(sequenceTransition);

			return sequenceTransition;
		}

		/**
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 * Dispatches when new state was created and ready to switch, but not switched yet or makes enter phase.
		 * As parameter sends new state.
		 */
		public function get onStateCreated():BBSignal
		{
			if (_onStateCreated == null) _onStateCreated = BBSignal.get(this);
			return _onStateCreated;
		}

		/**
		 * Dispatches when new transition was created but not started and makes enter phase.
		 * As parameter sends new transition.
		 */
		public function get onTransitionCreated():BBSignal
		{
			if (_onTransitionCreated == null) _onTransitionCreated = BBSignal.get(this);
			return _onTransitionCreated;
		}

		/**
		 */
		public function get isDisposed():Boolean
		{
			return _agent == null;
		}

		/**
		 */
		public function dispose():void
		{
			if (!isDisposed)
			{
				_agent = null;
				if (_currentState) _currentState.dispose();
				_currentState = null;
				if (_currentTransition) _currentTransition.interrupt();
				_currentTransition = null;
				if (_sequenceTransitions) _sequenceTransitions.interrupt();
				_currentTransition = null;

				_defaultState = null;

				if (_isStack)
				{
					_stack.dispose();
					_stack = null;
					_isStack = false;
				}

				// adds to pool
				put(this);
			}
		}

		/**
		 */
		public function rid():void
		{
			if (_onStateCreated) _onStateCreated.dispose();
			_onStateCreated = null;
			if (_onTransitionCreated) _onTransitionCreated.dispose();
			_onTransitionCreated = null;
		}

		////////////////////
		/// POOL ///////////
		////////////////////

		//
		static private var _pool:BBStack = new BBStack();

		/**
		 * Returns instance of FSM from pool.
		 */
		static public function get(p_agent:Object, p_initState:Class, p_isStack:Boolean = false):BBFSM
		{
			var fsm:BBFSM = _pool.pop() as BBFSM;

			if (fsm) fsm.initFSM(p_agent, p_initState, p_isStack);
			else fsm = new BBFSM(p_agent, p_initState, p_isStack);

			return fsm;
		}

		/**
		 */
		static private function put(p_fsm:BBFSM):void
		{
			_pool.push(p_fsm);
		}

		/**
		 * Removes all pools with ridding of all elements, but pool itself are not removed.
		 */
		static public function rid():void
		{
			_pool.dispose();
			_pool = new BBStack();
			ridEntityPool();
		}

		/////////////////
		// entity pool //
		/////////////////

		/**
		 */
		static private var _entityPool:Dictionary = new Dictionary();

		/**
		 */
		static private function getEntity(p_entityClass:Class):BBIFSMEntity
		{
			var entityInstance:BBIFSMEntity;
			var pool:BBStack = _entityPool[p_entityClass];

			if (pool && pool.size > 0) entityInstance = pool.pop() as BBIFSMEntity;
			else entityInstance = new p_entityClass();

			// is shared take bake entity to pool
			if (entityInstance.isShared) putEntity(entityInstance);

			return entityInstance;
		}

		/**
		 */
		static private function putEntity(p_entity:BBIFSMEntity):void
		{
			var entityClass:Class = p_entity.getClass();
			var pool:BBStack = _entityPool[entityClass];

			if (pool == null)
			{
				pool = new BBStack();
				_entityPool[entityClass] = pool;
			}

			//
			if (!p_entity.isShared || pool.size == 0) pool.push(p_entity);
		}

		/**
		 */
		static private function hasEntity(p_entityClass:Class):Boolean
		{
			return _entityPool[p_entityClass] != null;
		}

		/**
		 */
		static private function numEntities(p_entityClass:Class):int
		{
			return (_entityPool[p_entityClass] as BBStack).size;
		}

		/**
		 */
		static private function ridEntityPool():void
		{
			for (var entityClass:Object in _entityPool)
			{
				(_entityPool[entityClass] as BBStack).dispose();
				delete _entityPool[entityClass];
			}
		}
	}
}


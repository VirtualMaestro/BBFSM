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
		 * If 'true' mean instance fully destroying, without adding to pool.
		 * Only when invoke 'rid' method.
		 */
		private var _rid:Boolean = false;

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
		 * Changes to given state.
		 * p_force - forcing change. It needs when performs transition and at the same time need to change state.
		 * If p_force is 'false' changing states can't be performed. p_force should be 'true' for interrupts current transition and performs changing states.
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
		private function switchStates(p_newState:BBState, p_disposePreviousState:Boolean = false):void
		{
			if (_onStateCreated) _onStateCreated.dispatch(p_newState);

			_currentState.exit();
			if (p_disposePreviousState) _currentState.dispose();
			_currentState = p_newState;
			_currentState.enter();
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
		 * Starts performing transition of given transition's class.
		 * p_force - 'false' mean transition won't start if some other transition is performed.
		 *           'true' mean if some other transition is performed it is interrupted and starts perform given transition.
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
			var nextState:BBState = getState(transition.i_stateToClass);
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
		 * Starts to perform sequence transitions by given class.
		 * p_force - if 'true' any current performed transitions or sequence transitions is interrupted.
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
		 * If need skip current performed sequence transitions.
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
		 * If need permanent update in states of transitions.
		 * Method can be invoked every tick (enter frame) with set of delta time between invocations.
		 */
		public function update(p_deltaTime:int):void
		{
			if (_currentState.updateEnable) _currentState.update(p_deltaTime);
			if (_currentTransition && _currentTransition.updateEnable) _currentTransition.update(p_deltaTime);
			if (_sequenceTransitions && _sequenceTransitions.updateEnable) _sequenceTransitions.update(p_deltaTime);
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

		/**
		 * Gets instance from the pool of state by given class.
		 */
		[Inline]
		private function getState(p_stateClass:Class):BBState
		{
			var state:BBState = getEntity(p_stateClass) as BBState;
			initEntity(state);

			return state;
		}

		/**
		 * Gets instance from the pool of transition by given class.
		 */
		[Inline]
		private function getTransition(p_transitionClass:Class):BBTransition
		{
			var transition:BBTransition = getEntity(p_transitionClass) as BBTransition;
			initEntity(transition);

			return transition;
		}

		/**
		 * Gets instance from the pool of sequence transitions by given class.
		 */
		[Inline]
		private function getSequenceTransitions(p_sequenceTransitionClass:Class):BBSequenceTransitions
		{
			var sequenceTransition:BBSequenceTransitions = getEntity(p_sequenceTransitionClass) as BBSequenceTransitions;
			initEntity(sequenceTransition);

			return sequenceTransition;
		}

		/**
		 * Returns unique number of current instance.
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
		 * Determines if current instance already disposed.
		 */
		[Inline]
		final public function get isDisposed():Boolean
		{
			return _agent == null;
		}

		/**
		 * Method removes instance with possibility of re-use it again.
		 * Instance put to pool and use next time.
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
				if (!_rid) put(this);
			}
		}

		/**
		 * Completely removes instance without any chance to use it again.
		 */
		public function rid():void
		{
			_rid = true;

			dispose();

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

			// is shared take back entity to pool
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


/**
 * User: VirtualMaestro
 * Date: 25.06.13
 * Time: 18:11
 */
package bb_fsm
{
	import flash.utils.Dictionary;

	/**
	 * Class of finite state machine.
	 */
	final public class BBFSM
	{
		private var _agent:Object;
		private var _stack:BBStack;

		private var _currentState:BBState;
		private var _currentTransition:BBTransition;

		private var _defaultState:Class;
		private var _isStack:Boolean = false;
		private var _id:int = 0;

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
			if (isTransitioning)
			{
				if (p_force)
				{
					_currentTransition.interrupt();
					_currentTransition = null;
				}
				else return;
			}

			//
			var newState:BBState = getState(p_stateClass);

			if (_isStack)
			{
				_stack.push(_currentState);
				switchStates(newState);
			}
			else switchStates(newState).dispose();
		}

		/**
		 */
		[Inline]
		private function initState(p_state:BBState):void
		{
			p_state.i_agent = _agent;
			p_state.i_fsm = this;
		}

		/**
		 * Switched states - old state makes exit, new state enter.
		 * Returns previous state.
		 */
		[Inline]
		private function switchStates(p_newState:BBState):BBState
		{
			var prevState:BBState = _currentState;
			_currentState.exit();
			_currentState = p_newState;
			_currentState.enter();

			return prevState;
		}

		/**
		 */
		public function doTransition(p_transitionClass:Class, p_force:Boolean = false):void
		{
			if (isTransitioning)
			{
				if (p_force)
				{
					_currentTransition.interrupt();
					_currentTransition = null;
				}
				else return;
			}

			//
			var transition:BBTransition = getTransition(p_transitionClass);

			// stateFrom class is not the same as currentState, so need to change states before transition
			if (_currentState.getClass() != transition.i_stateFromClass)
			{
				changeState(transition.i_stateFromClass);
			}

			//
			var nextState:BBState = new transition.i_stateToClass();
			initState(nextState);
			transition.setStates(_currentState, nextState);
			transition.i_onCompleteCallback = transitionCompleteCallback;
			_currentTransition = transition;
			_currentTransition.enter();
		}

		/**
		 */
		private function transitionCompleteCallback():void
		{
			var prevState:BBState = switchStates(_currentTransition.stateTo);
			if (!_isStack) prevState.dispose();
			_currentTransition.dispose();
			_currentTransition = null;
		}

		/**
		 * Checks whether or not the transition.
		 */
		[Inline]
		final public function get isTransitioning():Boolean
		{
			return _currentTransition != null;
		}

		/**
		 */
		public function update(p_deltaTime:Number):void
		{
			_currentState.update(p_deltaTime);
			if (_currentTransition) _currentTransition.update(p_deltaTime);
		}

		/**
		 * Put state on top of stack.
		 */
		public function push(p_stateClass:Class):void
		{
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
				BBAssert.isTrue(_isStack, "you can't use this pop method if state machine isn't marked as stack", "BBFSM.pop");
			}

			if (_stack.size > 1)
			{
				_currentState.exit();
				_currentState.dispose();
				_stack.pop();
				_currentState = _stack.top as BBState;
				_currentState.enter();
			}
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
			initState(state);

			return state;
		}

		[Inline]
		private function getTransition(p_transitionClass:Class):BBTransition
		{
			var transition:BBTransition = getEntity(p_transitionClass) as BBTransition;
			transition.i_fsm = this;

			return transition;
		}

		/**
		 */
		public function get id():int
		{
			return _id;
		}

		/**
		 */
		[Inline]
		final public function get isDisposed():Boolean
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

		////////////////////
		/// POOL ///////////
		////////////////////

		//
		static private var _pool:Pool = new Pool();

		/**
		 * Returns instance of FSM from pool.
		 */
		static public function get(p_agent:Object, p_initState:Class, p_isStack:Boolean = false):BBFSM
		{
			var fsm:BBFSM = _pool.get() as BBFSM;

			if (fsm) fsm.initFSM(p_agent, p_initState, p_isStack);
			else fsm = new BBFSM(p_agent, p_initState, p_isStack);

			return fsm;
		}

		/**
		 */
		static private function put(p_fsm:BBFSM):void
		{
			_pool.put(p_fsm);
		}

		/**
		 */
		static public function rid():void
		{
			_pool.dispose();
			_pool = new Pool();
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
			var pool:Pool = _entityPool[p_entityClass];

			if (pool && pool.numInPool > 0) entityInstance = pool.get() as BBIFSMEntity;
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
			var pool:Pool = _entityPool[entityClass];

			if (pool == null)
			{
				pool = new Pool();
				_entityPool[entityClass] = pool;
			}

			//
			if (!p_entity.isShared || pool.numInPool == 0) pool.put(p_entity);
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
			return (_entityPool[p_entityClass] as Pool).numInPool;
		}

		/**
		 */
		static private function ridEntityPool():void
		{
			for (var entityClass:Object in _entityPool)
			{
				(_entityPool[entityClass] as Pool).dispose();
				delete _entityPool[entityClass];
			}
		}
	}
}

/**
 */
internal class Pool
{
	//
	private var _pool:Array;
	private var _numInPool:int = 0;

	/**
	 */
	public function Pool()
	{
		_pool = [];
	}

	/**
	 */
	public function put(p_obj:Object):void
	{
		_pool[_numInPool++] = p_obj;
	}

	/**
	 */
	public function get():Object
	{
		var obj:Object;
		if (_numInPool > 0)
		{
			obj = _pool[--_numInPool];
			_pool[_numInPool] = null;
		}

		return obj;
	}

	/**
	 */
	public function get numInPool():int
	{
		return _numInPool;
	}

	/**
	 */
	public function dispose():void
	{
		if (_pool && _numInPool > 0)
		{
			for (var i:int = 0; i < _numInPool; i++)
			{
				_pool[i] = null;
			}

			_pool.length = 0;
			_pool = null;
			_numInPool = 0;
		}
	}
}


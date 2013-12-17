/**
 * User: VirtualMaestro
 * Date: 28.06.13
 * Time: 16:04
 */
package bb_fsm
{
	/**
	 * Data structure stack.
	 */
	internal class BBStack
	{
		//
		private var _stack:Vector.<BBIDisposable>;
		private var _size:int = 0;

		/**
		 */
		public function BBStack()
		{
			_stack = new <BBIDisposable>[];
		}

		/**
		 */
		final public function push(p_element:BBIDisposable):void
		{
			_stack[_size++] = p_element;
		}

		/**
		 * Removes top element from stack.
		 */
		final public function pop():BBIDisposable
		{
			if (_size > 0)
			{
				var element:BBIDisposable = _stack[--_size];
				_stack[_size] = null;
				return element;
			}

			return null;
		}

		/**
		 * Gets top element. Doesn't removed it from stack.
		 */
		final public function get top():BBIDisposable
		{
			return _size > 0 ? _stack[_size - 1] : null;
		}

		/**
		 * Number elements in stack.
		 */
		final public function get size():int
		{
			return _size;
		}

		/**
		 * Disposes the stack.
		 */
		final public function dispose():void
		{
			if (_size > 0)
			{
				var element:BBIDisposable;
				for (var i:int = 0; i < _size; i++)
				{
					element = _stack[i];
					element.rid();
					_stack[i] = null;
				}

				_stack.length = 0;
				_stack = null;
				_size = 0;
			}
		}
	}
}

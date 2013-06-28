/**
 * User: VirtualMaestro
 * Date: 28.06.13
 * Time: 16:04
 */
package bb_fsm
{
	/**
	 * Data structure stack used for holding instances of BBState class.
	 */
	internal class BBStack
	{
		//
		private var _stack:Vector.<BBIFSMEntity>;
		private var _size:int = 0;

		/**
		 */
		public function BBStack()
		{
			_stack = new <BBIFSMEntity>[];
		}

		/**
		 */
		[Inline]
		final public function push(p_element:BBIFSMEntity):void
		{
			_stack[_size++] = p_element;
		}

		/**
		 * Removes top element from stack.
		 */
		[Inline]
		final public function pop():void
		{
			if (_size > 0) _stack[--_size] = null;
		}

		/**
		 * Gets top element. Doesn't removed it from stack.
		 */
		[Inline]
		final public function get top():BBIFSMEntity
		{
			return _size > 0 ? _stack[_size - 1] : null;
		}

		/**
		 * Number elements in stack.
		 */
		[Inline]
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
				for (var i:int = 0; i < _size; i++)
				{
					_stack[i] = null;
				}

				_stack.length = 0;
				_stack = null;
				_size = 0;
			}
		}
	}
}

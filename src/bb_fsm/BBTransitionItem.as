/**
 * User: VirtualMaestro
 * Date: 01.07.13
 * Time: 14:40
 */
package bb_fsm
{
	internal class BBTransitionItem implements BBIDisposable
	{
		public var transition:Class;
		public var delay:int;

		/**
		 */
		public function BBTransitionItem(p_transition:Class, p_delay:int)
		{
			transition = p_transition;
			delay = p_delay;
		}

		/**
		 */
		public function get isDisposed():Boolean
		{
			return transition == null;
		}

		/**
		 */
		public function dispose():void
		{
			if (!isDisposed)
			{
				transition = null;
				delay = 0;
			}
		}

		public function rid():void
		{
		}
	}
}

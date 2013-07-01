/**
 * User: VirtualMaestro
 * Date: 01.07.13
 * Time: 14:08
 */
package bb_fsm
{
	/**
	 */
	internal interface BBIDisposable
	{
		function get isDisposed():Boolean;
		function dispose():void;
		function rid():void;
	}
}

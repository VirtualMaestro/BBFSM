/**
 * User: VirtualMaestro
 * Date: 28.06.13
 * Time: 16:45
 */
package bb_fsm
{
	/**
	 * Generates unique ids.
	 */
	internal class BBUniqueId
	{
		//
		static private var _uniqueId:int = 0;

		/**
		 */
		static public function getId():int
		{
			return _uniqueId++;
		}
	}
}

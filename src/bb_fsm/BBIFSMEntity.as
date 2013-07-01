/**
 * User: VirtualMaestro
 * Date: 27.06.13
 * Time: 18:26
 */
package bb_fsm
{
	/**
	 * Interface of all FSM entity like State and Transition.
	 */
	internal interface BBIFSMEntity extends BBIDisposable
	{
		function enter():void;
		function exit():void;
		function update(p_deltaTime:Number):void;
		function get fsm():BBFSM;
		function get agent():Object;
		function getClass():Class;
		function get isShared():Boolean;
		function get id():int;
	}
}

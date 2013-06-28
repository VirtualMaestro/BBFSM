package bb_fsm
{
	/**
	 */
	internal class BBAssert
	{
		/**
		 */
		public static function isTrue(expression:Boolean, message:String = "", whereOccur:String = ""):void
		{
			if (!expression)
			{
				if (message == "" || message == null)
				{
					message = "[Assertion failed] - this expression must be true";
				}
				else
				{
					if (whereOccur != "") message = "ERROR: in " + whereOccur + ": " + message + "!";
					else message = "ERROR: " + message + "!";
				}

				throw new Error(message);
			}
		}
	}
}

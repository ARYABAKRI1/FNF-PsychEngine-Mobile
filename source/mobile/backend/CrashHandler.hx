package mobile.backend;

import haxe.CallStack;
import haxe.Exception;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import lime.utils.Log as LimeLogger;
import openfl.events.UncaughtErrorEvent;
import lime.system.System as LimeSystem;

class CrashHandler
{
	#if android
	var errored:Bool = false;
	#end
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#elseif hl
		hl.Api.setErrorHandler(onCriticalError);
		#end
	}

	private static function onError(event:UncaughtErrorEvent):Void
	{
		#if android
		if (!errored) {
		#end
		event.preventDefault();
		event.stopImmediatePropagation();

		final log:Array<String> = [];

		if (Std.isOfType(event.error, Error))
			log.push(cast(event.error, Error).message);
		else if (Std.isOfType(event.error, ErrorEvent))
			log.push(cast(event.error, ErrorEvent).text);
		else
			log.push(Std.string(event.error));

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					log.push('C Function');
				case Module(m):
					log.push('Module [$m]');
				case FilePos(s, file, line, column):
					log.push('$file [line $line]');
				case Method(classname, method):
					log.push('$classname [method $method]');
				case LocalFunction(name):
					log.push('Local Function [$name]');
			}
		}

		final msg:String = log.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('crash'))
				FileSystem.createDirectory('crash');

			File.saveContent('crash/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', msg);
		}
		catch (e:Exception)
			trace('Couldn\'t save error message. (${e.message})', null);
		#end

		SUtil.showPopUp(msg, "Error!" #if android, "OK", () -> LimeSystem.exit(1) #end);

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		#if js
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		js.Browser.window.location.reload(true);
		#elseif !android
		LimeSystem.exit(1);
		#elseif android
		errored = true;
		}
		#end
	}

	private static inline function onCriticalError(error:Dynamic):Void
	{
		#if android
		if (!errored) {
		#end
		final log:Array<String> = [Std.isOfType(error, String) ? error : Std.string(error)];

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					log.push('C Function');
				case Module(m):
					log.push('Module [$m]');
				case FilePos(s, file, line, column):
					log.push('$file [line $line]');
				case Method(classname, method):
					log.push('$classname [method $method]');
				case LocalFunction(name):
					log.push('Local Function [$name]');
			}
		}

		final msg:String = log.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('crash'))
				FileSystem.createDirectory('crash');

			File.saveContent('crash/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '-critical' + '.txt', msg);
		}
		catch (e:Exception)
			trace('Couldn\'t save error message. (${e.message})', null);
		#end

		SUtil.showPopUp(msg, "Critical Error!" #if android, "OK", () -> LimeSystem.exit(1) #end);

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		#if js
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		js.Browser.window.location.reload(true);
		#elseif !android
		LimeSystem.exit(1);
		#elseif android
		errored = true;
		}
		#end
	}
}

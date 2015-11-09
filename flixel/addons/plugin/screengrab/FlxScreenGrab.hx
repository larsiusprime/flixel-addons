package flixel.addons.plugin.screengrab;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.utils.UInt8Array;
import lime.graphics.ImageType;
import lime.graphics.opengl.GL;
import lime.graphics.PixelFormat;
import lime.utils.Int32Array;
import openfl.display.PNGEncoderOptions;
import openfl.events.Event;
import openfl.Lib;
import openfl.net.FileFilter;

#if !js
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flixel.addons.util.PNGEncoder;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import openfl.net.FileReference;

/**
 * Captures a screen grab of the game and stores it locally, optionally saving as a PNG.
 * 
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 */
class FlxScreenGrab extends FlxBasic
{
	public static var screenshot(default, null):Bitmap;
	
	private static var _hotkeys:Array<FlxKey>;
	private static var _autoSave:Bool = false;
	private static var _autoHideMouse:Bool = false;
	private static var _region:Rectangle;
	
	/**
	 * Defines the region of the screen that should be captured. If you need it to be a fixed location then use this.
	 * If you want to grab the whole SWF size, you don't need to set this as that is the default.
	 * Remember that if your game is running in a zoom mode > 1 you need to account for this here.
	 * 
	 * @param	X		The x coordinate (in Flash display space, not Flixel game world)
	 * @param	Y		The y coordinate (in Flash display space, not Flixel game world)
	 * @param	Width	The width of the grab region
	 * @param	Height	The height of the grab region
	 */
	public static function defineCaptureRegion(X:Int, Y:Int, Width:Int, Height:Int):Void
	{
		_region = new Rectangle(X, Y, Width, Height);
	}
	
	/**
	 * Clears a previously defined capture region
	 */
	public static function clearCaptureRegion():Void
	{
		_region = null;
	}
	
	/**
	 * Specify which key will capture a screen shot. Use the String value of the key in the same way FlxG.keys does (so "F1" for example)
	 * Optionally save the image to a file immediately. This uses the file systems "Save as" dialog window and pauses your game during the process.
	 * 
	 * @param	Key			The key(s) you press to capture the screen (i.e. [F1, SPACE])
	 * @param	SaveToFile	If true it will immediately encodes the grab to a PNG and open a "Save As" dialog window when the hotkey is pressed
	 * @param	HideMouse	If true the mouse will be hidden before capture and displayed afterwards when the hotkey is pressed
	 */
	public static function defineHotKeys(Keys:Array<FlxKey>, SaveToFile:Bool = false, HideMouse:Bool = false):Void
	{
		_hotkeys = Keys;
		_autoSave = SaveToFile;
		_autoHideMouse = HideMouse;
	}
	
	/**
	 * Clears all previously defined hotkeys
	 */
	public static function clearHotKeys():Void
	{
		_hotkeys = [];
		_autoSave = false;
		_autoHideMouse = false;
	}
	
	/**
	 * Takes a screen grab immediately of the given region or a previously defined region
	 * 
	 * @param	CaptureRegion	A Rectangle area to capture. This over-rides that set by "defineCaptureRegion". If neither are set the full SWF size is used.
	 * @param	Callback		A function that will receive the BitmapData when it's done processing
	 * @param	SaveToFile		Boolean If set to true it will immediately encode the grab to a PNG and open a "Save As" dialog window
	 * @param	HideMouse		Boolean If set to true the mouse will be hidden before capture and displayed again afterwards
	 */
	public static function grab(?CaptureRegion:Rectangle, ?Callback:BitmapData->Void, ?SaveToFile:Bool = false, HideMouse:Bool = false):Void
	{
		var bounds:Rectangle;
		
		if (CaptureRegion != null)
		{
			bounds = new Rectangle(CaptureRegion.x, CaptureRegion.y, CaptureRegion.width, CaptureRegion.height);
		}
		else if (_region != null)
		{
			bounds = new Rectangle(_region.x, _region.y, _region.width, _region.height);
		}
		else
		{
			bounds = new Rectangle(0, 0, FlxG.stage.stageWidth, FlxG.stage.stageHeight);
		}
		
		#if !FLX_NO_MOUSE
		if (HideMouse)
		{
			FlxG.mouse.visible = false;
		}
		#end
		
		Lib.screenShot(FlxG.stage, function(b:BitmapData) {
			
			if (screenshot == null) screenshot = new Bitmap();
			screenshot.bitmapData = b;
			
			if (SaveToFile)
			{
				save();
			}
			
			#if !FLX_NO_MOUSE
			if (HideMouse)
			{
				FlxG.mouse.visible = true;
			}
			#end
			
			if (Callback != null)
			{
				Callback(b);
			}
		
		},Std.int(bounds.x), Std.int(bounds.y), Std.int(bounds.width), Std.int(bounds.height));
	}
	
	private static function save(Filename:String = ""):Void
	{
		if (screenshot.bitmapData == null)
		{
			return;
		}
		
		if (Filename == "")
		{
			var date:String = Date.now().toString();
			var nameArray:Array<String> = date.split(":");
			date = nameArray.join("-");
			
			Filename = "grab-" + date + ".png";
		}
		else if (Filename.substr( -4) != ".png")
		{
			Filename = Filename + ".png";
		}
		
		var png:ByteArray = null;
		
	#if flash
		png = PNGEncoder.encode(screenshot.bitmapData);
	#else
		png = screenshot.bitmapData.encode(screenshot.bitmapData.rect, new PNGEncoderOptions());
	#end
	
		FlxG.bitmapLog.add(screenshot.bitmapData, "screenshot");
		
		var file:FileReference = new FileReference();
		
		file.save(png, Filename);
	}
	
	
	override public function update(elapsed:Float):Void
	{
		#if !FLX_NO_KEYBOARD
		if (FlxG.keys.anyJustReleased(_hotkeys))
		{
			grab(null, _autoSave, _autoHideMouse);
		}
		#end
	}
	
	override public function destroy():Void
	{
		clearCaptureRegion();
		clearHotKeys();
	}
}
#end
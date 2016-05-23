package flixel.addons.editors.tiled;

import haxe.xml.Fast;

/**
 * Copyright (c) 2013 by Samuel Batista
 * (original by Matt Tuttle based on Thomas Jahn's. Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledImageTile 
{
	public var id:String;
	public var width:Float;
	public var height:Float;
	public var source:String;
	
	public function new(Source:Fast)
	{
		if (Source.hasNode.image)
		{
			for (img in Source.nodes.image)
			{
				if (img == null) continue;
				source = img.has.source ? img.att.source : "";
				width = img.has.width ? Std.parseFloat( img.att.width) : 0.0;
				height = img.has.height ? Std.parseFloat(img.att.height) : 0.0;
			}
		}
		else
		{
			id = "";
			width = 0;
			height = 0;
			source = "";
		}
	}
}
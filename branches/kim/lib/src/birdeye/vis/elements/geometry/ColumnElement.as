/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package birdeye.vis.elements.geometry
{
	import birdeye.vis.VisScene;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.elements.collision.*;
	import birdeye.vis.guides.renderers.ArcPath;
	import birdeye.vis.guides.renderers.RasterRenderer;
	import birdeye.vis.guides.renderers.RectangleRenderer;
	import birdeye.vis.interfaces.IBoundedRenderer;
	import birdeye.vis.interfaces.IEnumerableScale;
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.interfaces.IScale;
	import birdeye.vis.scales.*;
	
	import com.degrafa.IGeometry;
	import com.degrafa.core.IGraphicsFill;
	import com.degrafa.geometry.Line;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import mx.core.ClassFactory;

	public class ColumnElement extends StackElement 
	{
		private var _ggArray:Array;
		
		override public function get elementType():String
		{
			return "column";
		}
		
		public function ColumnElement()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if (!itemRenderer)
				itemRenderer = new ClassFactory(RectangleRenderer);

			if (stackType == STACKED100 && chart)
			{
				if (scale2 && scale2 is INumerableScale)
					INumerableScale(scale2).max = chart.maxStacked100;
			}
		}

		private var poly:IGeometry;
		/** @Private 
		 * Called by super.updateDisplayList when the element is ready for layout.*/
		override public function drawElement():void
		{
//			var renderer:ISeriesDataRenderer = new itemRenderer();
			
			if (isReadyForLayout() && _invalidatedElementGraphic)
			{
trace (getTimer(), "drawing column ele");

				super.drawElement();
				removeAllElements();

				var pos1:Number, pos2:Number, zPos:Number = NaN;
				var j:Object;
				
				var ttShapes:Array;
				var ttXoffset:Number = NaN, ttYoffset:Number = NaN;
				
				var baseScale2:Number = getDim2MinPosition(scale2);
				var tmpSize:Number, colWidth:Number = 0; 
				if (scale1)
				{
					if (scale1 is IEnumerableScale)
						tmpSize = scale1.size/IEnumerableScale(scale1).dataProvider.length * chart.columnWidthRate;
					else if (scale1 is INumerableScale)
						tmpSize = scale1.size / 
								(INumerableScale(scale1).max - INumerableScale(scale1).min) * chart.columnWidthRate;

					var constTmpSize:Number = tmpSize;
				}
	
				ggIndex = 0;
 	
				if (chart.coordType == VisScene.POLAR)
				{
					var arcSize:Number = NaN;
			
					var angleInterval:Number;
					if (scale1) 
						angleInterval = scale1.scaleInterval * chart.columnWidthRate;
						
					switch (_stackType)
					{
						case STACKED:
							arcSize = angleInterval/_total;
							break;
						case OVERLAID:
						case STACKED100:
							arcSize = angleInterval;
							break;
					}
					constTmpSize = arcSize;
				}
				
				var tmpDim2:String;
				var innerBase2:Number;
				for (var cursorIndex:uint = 0; cursorIndex<_dataItems.length; cursorIndex++)
				{
	 				if (graphicsCollection.items && graphicsCollection.items.length>ggIndex)
						gg = graphicsCollection.items[ggIndex];
					else
					{
						gg = new DataItemLayout();
						graphicsCollection.addItem(gg);
					}
					gg.target = this;
					ggIndex++;

					var currentItem:Object = _dataItems[cursorIndex];
					
					var tmpArray:Array = (dim2 is Array) ? dim2 as Array : [String(dim2)];
					
					innerBase2 = 0;
					j = currentItem[dim1];

					for (var i:Number = 0; i<tmpArray.length; i++)
					{
						tmpDim2 = tmpArray[i];
						
						if (scale1)
						{
							pos1 = scale1.getPosition(currentItem[dim1]);
						}
						
						if (scale2)
						{
							
							if (_stackType == STACKED100)
							{
								baseScale2 = scale2.getPosition(baseValues[j] + innerBase2);
								pos2 = scale2.getPosition(
									baseValues[j] + Math.max(0,currentItem[tmpDim2] + innerBase2));
							} else {
								pos2 = scale2.getPosition(currentItem[tmpDim2] + innerBase2);
							}
							dataFields["dim2"] = tmpArray[i];
						}
						
						var scale2RelativeValue:Number = NaN;
		
						// TODO: fix stacked100 on 3D
						if (scale3)
						{
							zPos = scale3.getPosition(currentItem[dim3]);
							scale2RelativeValue = scale3.size - zPos;
						}
		
						if (colorScale)
						{
							var col:* = colorScale.getPosition(currentItem[colorField]);
							if (col is Number)
								fill = new SolidFill(col);
							else if (col is IGraphicsFill)
								fill = col;
						} 
		
						if (sizeScale)
						{
							_size = sizeScale.getPosition(currentItem[sizeField]);
							if (chart.coordType == VisScene.CARTESIAN)
								tmpSize = constTmpSize * _size;
							else
								arcSize = constTmpSize * _size;
						}

						if (chart.coordType == VisScene.CARTESIAN)
						{
							switch (_stackType)
							{
								case OVERLAID:
									colWidth = tmpSize;
									pos1 = pos1 - tmpSize/2;
									break;
								case STACKED100:
									colWidth = tmpSize;
									pos1 = pos1 - tmpSize/2;
									ttShapes = [];
									ttXoffset = -20;
									ttYoffset = 55;
									if (chart.customTooltTipFunction == null)
									{
										var line:Line = new Line(pos1+ colWidth/2, pos2, pos1 + colWidth/2 + ttXoffset/3, pos2 + ttYoffset);
										line.stroke = new SolidStroke(0xaaaaaa,1,2);
						 				ttShapes[0] = line;
									}
									break;
								case STACKED:
									pos1 = pos1 + tmpSize/2 - tmpSize/_total * (_stackPosition + 1);
									colWidth = tmpSize/_total;
									break;
							}
							
							var innerColWidth:Number;
							switch (_collisionType)
							{
								case OVERLAID:
									innerColWidth = colWidth;
									break;
								case STACKED100:
									innerColWidth = colWidth;
									baseScale2 = scale2.getPosition(innerBase2);
									innerBase2 += currentItem[tmpDim2];
									break;
								case STACKED:
									innerColWidth = colWidth/tmpArray.length;
									pos1 = pos1 + innerColWidth * i;
									if (ttShapes && ttShapes[0] is Line)
									{
						 				Line(ttShapes[0]).x = pos1 + innerColWidth/2;
						 				Line(ttShapes[0]).x1 = pos1 + innerColWidth/2 + ttXoffset/3;
									}
									break;
							}
							
			 				var bounds:Rectangle = new Rectangle(pos1, pos2, innerColWidth, baseScale2 - pos2);
			
							// scale2RelativeValue is sent instead of zPos, so that the axis pointer is properly
							// positioned in the 'fake' z axis, which corresponds to a real y axis rotated by 90 degrees
  							createTTGG(currentItem, dataFields, pos1 + innerColWidth/2, pos2, scale2RelativeValue, 
  										3, i, ttShapes,ttXoffset,ttYoffset,true);
 			 
							if (dim3)
							{
								if (!isNaN(zPos))
								{
									gg = new DataItemLayout();
									gg.target = this;
									graphicsCollection.addItem(gg);
/* 									ttGG.posZ = ttGG.z = gg.posZ = gg.z = zPos;
 */								} else
									zPos = 0;
							}
			
							if (ttGG && _extendMouseEvents)
								gg = ttGG;
							
			//				poly = renderer.getGeometry(bounds);
			
 			 				if (_source)
								poly = new RasterRenderer(bounds, _source);
			 				else 
								poly = itemRenderer.newInstance();
			
							if (poly is IBoundedRenderer) (poly as IBoundedRenderer).bounds = bounds;
							poly.fill = fill;
							poly.stroke = stroke; 
							gg.geometryCollection.addItemAt(poly,0);  
						} else if (chart.coordType == VisScene.POLAR)
						{
	/* 						var arcCenterX:Number = chart.origin.x - pos2;
							var arcCenterY:Number = chart.origin.y - pos2;
	 */
							var startAngle:Number; 
							switch (_stackType) 
							{
								case STACKED:
									startAngle = pos1 - angleInterval/2 + constTmpSize *_stackPosition;
									break;
								case OVERLAID:
								case STACKED100:
									startAngle = pos1 - angleInterval/2;
									break;
							}
							
							var innerAngleSize:Number;

							switch (_collisionType)
							{
								case OVERLAID:
									innerAngleSize = arcSize;
									startAngle = startAngle;
									break;
								case STACKED100:
									innerAngleSize = arcSize;

									innerBase2 += currentItem[tmpDim2];
									break;
								case STACKED:
									innerAngleSize = arcSize/tmpArray.length;
									startAngle = startAngle + innerAngleSize * i;
									if (ttShapes && ttShapes[0] is Line)
									{
						 				Line(ttShapes[0]).x = pos1 + innerAngleSize/2;
						 				Line(ttShapes[0]).x1 = pos1 + innerAngleSize/2 + ttXoffset/3;
									}
									break;
							}
							
							var wSize:Number, hSize:Number;
							wSize = hSize = pos2*2;
			
							var xPos:Number = PolarCoordinateTransform.getX(startAngle+innerAngleSize/2, pos2, chart.origin);
							var yPos:Number = PolarCoordinateTransform.getY(startAngle+innerAngleSize/2, pos2, chart.origin); 
		 	
 							createTTGG(currentItem, dataFields, xPos, yPos, NaN, _rendererSize, i);
 							
							if (ttGG && _extendMouseEvents)
								gg = ttGG;
								
							var arc:IGeometry;
							
							arc = 
								new ArcPath(baseScale2, pos2, startAngle, innerAngleSize, chart.origin);
	//								new EllipticalArc(arcCenterX, arcCenterY, wSize, hSize, startAngle, arcSize, "pie");
			
							arc.fill = fill;
							arc.stroke = stroke;
							gg.geometryCollection.addItemAt(arc,0); 
						}
		
						if (_showItemRenderer)
						{
							var shape:IGeometry = itemRenderer.newInstance();
							if (shape is IBoundedRenderer) (shape as IBoundedRenderer).bounds = bounds;
							shape.fill = fill;
							shape.stroke = stroke;
							gg.geometryCollection.addItem(shape);
						}
					}
				}
	
				if (dim3)
					zSort();

				_invalidatedElementGraphic = false;
trace (getTimer(), "drawing column ele");
			}
		}
		
		private function getDim2MinPosition(s2:IScale):Number
		{
			var pos2:Number;
			if (s2 && s2 is INumerableScale)
			{
				if (!isNaN(_baseAt))
					pos2 = s2.getPosition(_baseAt);
				else
					pos2 = s2.getPosition(INumerableScale(s2).min);
			}
			return pos2;
		}
	}
}
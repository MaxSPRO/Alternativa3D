/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.animation {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.animation.events.NotifyEvent;
	import alternativa.engine3d.core.Object3D;

	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	use namespace alternativa3d;
	/**
	 * Controls animation playback and blending. I.e. it animates model using information
	 * stored in  <code>AnimationClip</code>-s and generated by <code>AnimationSwitcher</code>
	 * and <code>AnimationCouple</code> blenders.
	 * You have to call method <code>update()</code> each frame,
	 * which refreshes all child animation clips and blenders, which return
	 * list of properties and values to controller after that. You can use this list
	 * to set those properties. Controller sets those values and as a result
	 * the animation goes on. Animation control is carried out with the
	 * help of animated flag, and with <code>AnimationSwitcher</code> blender,
	 * which can transfer clip from active state to passive and vice versa.
	 *
     *
     * @see alternativa.engine3d.animation.AnimationClip
     * @see alternativa.engine3d.animation.AnimationCouple
     * @see alternativa.engine3d.animation.AnimationSwitcher
	 */
	public class AnimationController {

		/**
		 * @private 
		 */
		private var _root:AnimationNode;

		/**
		 * @private 
		 */
		private var _objects:Vector.<Object>;
		/**
		 * @private 
		 */
		private var _object3ds:Vector.<Object3D> = new Vector.<Object3D>();
		/**
		 * @private 
		 */
		private var objectsUsedCount:Dictionary = new Dictionary();

		/**
		 * @private 
		 */
		private var states:Object = new Object();
//		private var datasList:BlendedData;

		/**
		 * @private 
		 */
		private var lastTime:int = -1;

		/**
		 * @private 
		 */
		alternativa3d var nearestNotifyers:AnimationNotify;

		/**
		 * Creates a AnimationController object.
		 */
		public function AnimationController() {
		}

		/**
		 * Root of the animation tree.
		 */
		public function get root():AnimationNode {
			return _root;
		}

		/**
		 * @private 
		 */
		public function set root(value:AnimationNode):void {
			if (_root != value) {
				if (_root != null) {
					_root.setController(null);
					_root._isActive = false;
				}
				if (value != null) {
					value.setController(this);
					value._isActive = true;
				}
				this._root = value;
			}
		}

		/**
		 * Plays animations on the time interval passed since the last <code>update()</code> call.
		 * If <code>freeze()</code> method was called after the last <code>update(),</code>
		 * animation will continue from that moment.
		 */
		public function update():void {
			var interval:Number;
			if (lastTime < 0) {
				lastTime = getTimer();
				interval = 0;
			} else {
				var time:int = getTimer();
				interval = 0.001*(time - lastTime);
				lastTime = time;
			}
			if (_root == null) {
				return;
			}
			var data:AnimationState;
			// Cleaning
			for each (data in states) {
				data.reset();
			}
			_root.update(interval, 1);
			// Apply the animation
			for (var i:int = 0, count:int = _object3ds.length; i < count; i++) {
				var object:Object3D = _object3ds[i];
				data = states[object.name];
				if (data != null) {
					data.apply(object);
				}
			}
			// Calls the notifications
			for (var notify:AnimationNotify = nearestNotifyers; notify != null;) {
				if (notify.willTrigger(NotifyEvent.NOTIFY)) {
					notify.dispatchEvent(new NotifyEvent(notify));
				}
				var nt:AnimationNotify = notify;
				notify = notify.processNext;
				nt.processNext = null;
			}
			nearestNotifyers = null;
		}

		/**
		 * @private 
		 */
		alternativa3d function addObject(object:Object):void {
			if (object in objectsUsedCount) {
				objectsUsedCount[object]++;
			} else {
				if (object is Object3D) {
					_object3ds.push(object);
				} else {
					_objects.push(object);
				}
				objectsUsedCount[object] = 1;
			}
		}

		/**
		 * @private 
		 */
		alternativa3d function removeObject(object:Object):void {
			var used:int = objectsUsedCount[object];
			used--;
			if (used <= 0) {
				var index:int;
				var j:int;
				var count:int;
				if (object is Object3D) {
					index = _object3ds.indexOf(object);
					count = _object3ds.length - 1;
					j = index + 1;
					while (index < count) {
						_object3ds[index] = _object3ds[j];
						index++;
						j++;
					}
					_object3ds.length = count;
				} else {
					index = _objects.indexOf(object);
					count = _objects.length - 1;
					j = index + 1;
					while (index < count) {
						_objects[index] = _objects[j];
						index++;
						j++;
					}
					_objects.length = count;
				}
				delete objectsUsedCount[object];
			} else {
				objectsUsedCount[object] = used;
			}
		}

		/**
		 * @private 
		 */
		alternativa3d function getState(name:String):AnimationState {
			var state:AnimationState = states[name];
			if (state == null) {
				state = new AnimationState();
				states[name] = state;
			}
			return state;
		}

		/**
		 * Freezes internal time counter till the next <code>update()<code> call.
		 * 
		 * @see #update
		 */
		public function freeze():void {
			lastTime = -1;
		}

	}
}

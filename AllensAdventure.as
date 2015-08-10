package  {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.getTimer;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	
	public class AllensAdventure extends MovieClip {
		
		//constants
			static const gravity:Number = 0.004;
			static const edgeXDistance:Number = 320;
			static const edgeYDistance:Number = 200;
		
		//variables and objects
			private var floorObjects:Array;
			private var wallObjects:Array;
			private var otherObjects:Array;
			private var stanObjects:Array;
			private var pauseObjects:Array;
			private var collectedAllBones:Boolean = false;			
			private var collectedABanana:Boolean = false;
			private var bonesLeft:int = 0;
			private var bonesTotal:int = 0;
			private var bonesCollected:int = 0;
			private var bananasTotal:int = 0;
			private var bananasCollected:int = 0;
			private var allBonesBonus:int = 0;
			private var levelBonus:int = 0;
			private var levelsCompleted:int = 0;
			private var goodScore:Good = new Good;
			private var badScore:Bad = new Bad;
			private var goodPointsStep:int = 0;
			private var badPointsStep:int = 0;
			
			private var allen:Object;
			private var stan:Object;
			private var sky:Object;
			private var dustStep:uint = 0;
			private var dustGone:DustCloud = new DustCloud;
			private var scaleIncrement:Number = 0.25;
			
			private var gameMode:String = "start";
			private var levelHighScore:Number = 0;
			private var gameScore:int;
			private var totalScore:Number;
			var stanTimeLimit:int;
			
			var saveData:SharedObject;
			var myInput:TextField = new TextField();
			var cFrame:int = 0;
			var upArrowP:Boolean = false;
			var downArrowP:Boolean = false;
			var enterP:Boolean = false;
			var selectingP:int = 0;
			var retryDialog:RetryDialog = new RetryDialog();
			var pauseDialog:PauseDialog = new PauseDialog();
			var dialog:Dialog = new Dialog();
			var selectorP:Object;
			
			private var platformStartTime:uint = 0;
			private var platformGameTime:Number = 0;
			private var animDiff:uint;
			private var lastTime:Number = 0;
			private var idleStartTime:Number;
			private var idleTime:Number = 0;
			private var pauseStartTime:Number = 0;
			private var pauseTime:Number = 0;
			
			private var badSound:BadSound = new BadSound;
			private var goodSound:GoodSound = new GoodSound;
			private var highScoreSound:HighScoreSound = new HighScoreSound;
			private var allBonesSound:AllBonesSound = new AllBonesSound;
			private var gameMusicSound:GameMusicSound = new GameMusicSound;
			private var stanGoneSound:StanGoneSound = new StanGoneSound;
			private var retrySound:RetrySound = new RetrySound;
			private var gameMusicChannel:SoundChannel = new SoundChannel();
			private var volumeDown:SoundTransform = new SoundTransform(.4,0);
			private var volumeUp:SoundTransform = new SoundTransform(1,0);
			

		public function startAllensAdventure() {
			// constructor code
			animDiff = 0;
			gameScore = 0;
			gameMode = "play";
			idleStartTime = getTimer();
		}
		
		//sets the level up to play, starts most things ready for the player
		public function startGameLevel() {
			gameMusicChannel = gameMusicSound.play(0,10);
			gameMusicChannel.soundTransform = volumeUp;
			createAllen();
			createStan();
			examineLevel();

			gameMode = "play";
			addScore(0);

			platformGameTime = 0;
			platformStartTime = getTimer();
			stage.addEventListener(Event.ENTER_FRAME,gameLoop);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
		}		
		
		//builds allen according to these parameters
		public function createAllen() {
			allen = new Object();
			allen.mc = gamelevel.allen;
			allen.dx = 0.0;
			allen.dy = 0.0;
			allen.inAir = false;
			allen.isMoving = false;
			allen.sit = true;
			allen.direction = 1;
			allen.animstate = "sit";
			allen.standAnimation = new Array(1,2,3,4);
			allen.sitAnimation = new Array(5,6,7,8);
			allen.walkAnimation = new Array(9,10);
			allen.animstep = 0;
			allen.jump = false;
			allen.moveLeft = false;
			allen.moveRight = false;
			allen.jumpSpeed = .8;
			allen.walkSpeed = .3;
			allen.width = 32;
			allen.height = 32;
			allen.startx = allen.mc.x;
			allen.starty = allen.mc.y;
			
		}
		
		//builds stan according to these parameters
		public function createStan() {
			stan = new Object();
			stan.mc = gamelevel.stan;
			stan.animstate = "sitting";
			stan.sitAnimation = new Array(1,2,3,4);
			stan.gone = new Array(5);
			stan.mmb = new Array(6,7,8,9);
			stan.animstep = 0;
			stan.width = 32;
			stan.height = 32;
			stan.x = stan.mc.x;
			stan.y = stan.mc.y;
		}
		
		//finds the 'gamelevel' movie clip and looks at all the 
		//tiles present and puts them into an array according to type
		public function examineLevel() {
			floorObjects = new Array();
			wallObjects = new Array();
			otherObjects = new Array();
			stanObjects = new Array();
			
			//finds all the children of the 'gamelevel' movie clip
			for (var i:int=0;i<this.gamelevel.numChildren;i++) {
				var mc = this.gamelevel.getChildAt(i);
				
				//if the child is a floor movie clip put it in an array with these properties
				if (mc is Floor) {
					var floorObject:Object = new Object();
					floorObject.mc = mc;
					floorObject.leftside = mc.x;
					floorObject.rightside = mc.x+mc.width;
					floorObject.topside = mc.y;
					floorObject.bottomside = mc.y+mc.height;
					floorObjects.push(floorObject);
				} 
				
				//if the child is a wall movie clip put it in an array with these properties
				else if (mc is Wall) {
					var wallObject:Object = new Object();
					wallObject.mc = mc;
					wallObject.leftside = mc.x;
					wallObject.rightside = mc.x+mc.width;
					wallObject.topside = mc.y;
					wallObject.bottomside = mc.y+mc.height;
					wallObjects.push(wallObject);
				} 
				
				//if the child is any of these put them into an array and count how many of each
				//if its stan put him in his own array as well
				else if ((mc is Bone) || (mc is Banana || mc is Cloud || mc is Secret)) {
						otherObjects.push(mc);
					if (mc is Bone) {
						bonesLeft++;
						bonesTotal++;
					}
					if (mc is Banana) {
						bananasTotal++;
					}
				}
				if (mc is Stan) {
					stanObjects.push(mc);
				}
			}
		}
		
		//listen for key down events but only if the game is ready to play and after a short pause
		//sets allen to be moving and not sitting, if space is pressed he jumps
		public function keyDownFunction(event:KeyboardEvent) {
			if (gameMode != "play" || platformGameTime < 0.01) return;
			
			if (event.keyCode == 37) {
				allen.moveLeft = true;
				allen.isMoving = true;
				allen.sit = false;
			} else if (event.keyCode == 39) {
				allen.moveRight = true;
				allen.isMoving = true;
				allen.sit = false;
			} else if (event.keyCode == 32) {
				allen.isMoving = true;
				allen.sit = false;
				if (!allen.inAir) {
					allen.jump = true;					
				}
				
			//if esc pressed open the pause menu
			} else if (event.keyCode == 27) {
				gameMode = "paused";
				pauseMenu();
			}
		}
		
		//on key up allen is not moving but is still not sitting.  if allen is still in the air he is moving
		public function keyUpFunction(event:KeyboardEvent) {
			if (event.keyCode == 37) {
				allen.moveLeft = false;
				allen.isMoving = false;
			} else if (event.keyCode == 39) {
				allen.moveRight = false;
				allen.isMoving = false;
			} else if (event.keyCode == 32) {
				if (allen.inAir) {
					allen.jump = false;
					allen.isMoving = true;
					allen.sit = false;
				}
				if (allen.moveLeft == false && allen.moveRight == false) {
					allen.isMoving = false;
				}
			}
		}
		
		//main game loop.  listens and updates the game on each frame
		//deals with the timers for game time and how long allen is idle
		public function gameLoop(event:Event) {
			if (lastTime == 0) lastTime = getTimer();
			animDiff = getTimer() - lastTime;
			lastTime += animDiff;
			
			if (allen.isMoving == false && allen.inAir == false) {
				idleTime = (getTimer() - idleStartTime) / 1000;

			}
			if (allen.isMoving == true) {
				allen.sit = false;
				idleStartTime = getTimer();
				idleTime = 0;
			}

			platformGameTime = ((getTimer() - platformStartTime)/1000);
			levelTime.text = String(platformGameTime.toFixed(3));			

			if (gameMode == "play") {
				moveAllen(allen,animDiff);
				moveStan(stan,animDiff);
				monitorStan();
				checkCollisions();
				scrollWithAllen();
			}
		}
		
		//if esc is pressed this function is called
		//adds a dialog box with a pause menu
		public function pauseMenu() {
			
			if (gameMode == "paused") {
				pauseStartTime = getTimer();
				pauseDialog.x = 320;
				pauseDialog.y = 240;
				pauseDialog.name = "pauseDialog";
				addChild(pauseDialog);
				pauseDialog.focusRect = false;
				stage.focus = pauseDialog;
				pauseDialog.message.text = "Paused";
				pauseDialog.mainMenuButton.selectionText.text = "Main Menu";
				pauseDialog.restartLevelButton.selectionText.text = "Restart";
				pauseDialog.resumeButton.selectionText.text = "Resume";
				gameMusicChannel.soundTransform = volumeDown;
				pauseScreen();
			}
		}
				
		//removes listeners from the game level and adds it to the pause menu
		//sets what the selector is to start selecting
		public function pauseScreen() {
			examineP();
			addSelectorP();			
			selectingP = 0;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownFunctionP);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpFunctionP);
			stage.addEventListener(Event.ENTER_FRAME, pLoop);	
			stage.removeEventListener(Event.ENTER_FRAME,gameLoop);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
		}
		
		//examines the pause dialog and finds the buttons to put in an array
		public function examineP() {
			pauseObjects = new Array();
			
			for (var i:int=0;i<pauseDialog.numChildren;i++) {
				var mcP = pauseDialog.getChildAt(i);
		
				if (mcP is Button) {
					var pButton:Object = new Object();
					pButton.mcP = mcP;
					pButton.xpos = mcP.x;
					pButton.ypos = mcP.y;
					pButton.width = mcP.width;
					pButton.height = mcP.height;
					pButton.name = mcP.name;
					pauseObjects.push(pButton);
				}
			}
		}
		
		//creates the selectors properties
		public function addSelectorP() {
			selectorP = new Object();
			selectorP = pauseDialog.selectorP;
			selectorP.width = pauseObjects[0].width;
			selectorP.height = pauseObjects[0].height;
			selectorP.x = pauseObjects[0].xpos;
			selectorP.y = pauseObjects[0].ypos;
		}

		//listens for key presses and updates the selectors properties according
		//to the next or previous object in the array
		public function keyDownFunctionP(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				enterP = true;
				
			} else if (event.keyCode == 38) {
				upArrowP = true;
				selectingP--;
				if (selectingP <= -1) {
					selectingP = pauseObjects.length-1;
				}
			} else if (event.keyCode == 40) {
				downArrowP = true;
				selectingP++;
				
				if (selectingP >= pauseObjects.length) {
					selectingP = 0;
				}
			}
		}
			
		public function keyUpFunctionP(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				enterP = false;
				
			} else if (event.keyCode == 38) {
				upArrowP = false;
				
			} else if (event.keyCode == 40) {
				downArrowP = false;
			}
		}
		
		//loop for the pause menu
		//sets the amount of time the game has been paused
		public function pLoop(event:Event) {
			if (gameMode == "paused") {
			checkSelectorP();

			pauseTime = (getTimer() - pauseStartTime);

			}
		}
			
		//on a button press, gets the index of the object in the array
		//and applies that objects properties to the selector
		//if enter is pressed, depending on what button the selector is over,
		//either restart, exit to main menu, or resume
		public function checkSelectorP() {
			if (downArrowP) {
				selectorP.y = pauseObjects[selectingP].ypos;		
				selectorP.height = pauseObjects[selectingP].height;		
				selectorP.width = pauseObjects[selectingP].width;		
			}
			if (upArrowP) {
				selectorP.y = pauseObjects[selectingP].ypos;
				selectorP.height = pauseObjects[selectingP].height;		
				selectorP.width = pauseObjects[selectingP].width;		
			}
			
			if (pauseDialog.selectorP.hitTestObject(pauseDialog.mainMenuButton)) {
				if (enterP) {
					levelsCompleted = 0;
					cFrame = 4;
					gameMusicChannel.stop();
					startChannel = startThemeSound.play(0,10);
					pChoice();
				}
			}
			
			if (pauseDialog.selectorP.hitTestObject(pauseDialog.restartLevelButton)) {
				if (enterP) {
					stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunctionP);
					stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunctionP);
					stage.removeEventListener(Event.ENTER_FRAME,pLoop);
					enterP = false;
					removeChild(MovieClip(root).levelTime);
					removeChild(pauseDialog);
					gameMusicChannel.stop();
					retryCleanUp();
				}
			}
			if (pauseDialog.selectorP.hitTestObject(pauseDialog.resumeButton)) {
				if (enterP) {
					cFrame = currentFrame;
					resume();
				}
			}
		}
		
		//after setting properties to send the game to the main menu,
		//calls the clean up function and jumps to main menu
		public function pChoice() {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunctionP);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunctionP);
			stage.removeEventListener(Event.ENTER_FRAME,pLoop);
			enterP = false;
			removeChild(MovieClip(root).levelTime);
			removeChild(pauseDialog);
			cleanUp();
		}
		
		//gives listeners and focus back to the stage and removes the pause dialog box
		//sets the time back to the time when paused and lets the player keep playing
		public function resume() {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunctionP);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunctionP);
			stage.removeEventListener(Event.ENTER_FRAME,pLoop);
			gameMode = "play";
			platformStartTime += pauseTime;
			enterP = false;
			stage.addEventListener(Event.ENTER_FRAME,gameLoop);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
			removeChild(pauseDialog);
			gameMusicChannel.soundTransform = volumeUp;
			stage.focus = stage;
		}
		
		//tells stan what state to be in depending on the game time
		public function moveStan(char:Object, animDiff:Number) {
			if (animDiff<1) return;
			
			var newAnimState:String = "sitting";
			
			char.animstate = newAnimState;
			
			if (char.animstate == "sitting") {
				char.animstep += animDiff / 60;
				if (char.animstep > char.sitAnimation.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.sitAnimation[Math.floor(char.animstep)]);
			}
			
			if (currentFrame == 15) {
				char.animstate = "mmb";
				char.animstep += animDiff / 60;
				if (char.animstep > char.mmb.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.mmb[Math.floor(char.animstep)]);
			}
			
			if (platformGameTime > stanTimeLimit) {
				char.animstate = "gone";
				
				stanGone();
			}
		}
		
		//if the player has taken too long for the level adds a dust cloud
		public function stanGone() {
			if (stan.animstate == "gone") {
				stan.mc.gotoAndStop(stan.animstate);
				dustGone.x = stan.mc.x;
				dustGone.y = stan.mc.y-16;
				dustGone.scaleX = .5;
				dustGone.scaleY = .5;
				dustBurst();				
			}
		}
		
		//call function to animate the dust cloud
		public function dustBurst() {
			dustGone.alpha = 0;
			gamelevel.addChild(dustGone);
			this.addEventListener(Event.ENTER_FRAME,dust);
		}
		
		//animates the dust cloud
		public function dust(event:Event) {
			dustStep++;
			scaleIncrement += 0.03;
			if (dustStep == 1) {
				playSound(stanGoneSound);
			}
			if (dustStep < 50) {
				dustGone.alpha = (1 - (dustStep/50));
				dustGone.scaleX = 0.5 + scaleIncrement;
				dustGone.scaleY = 0.5 + scaleIncrement;
			}
			if (dustStep >= 50) {
				dustStep = 50;
				this.removeEventListener(Event.ENTER_FRAME,dust);
			}
		}
				
		//animates allen on player input and other events
		public function moveAllen(char:Object, animDiff:Number) {
			
			if (animDiff <1) return;
			
			var vertChange:Number = (char.dy * animDiff) + (animDiff * gravity);
			if (vertChange > 15.0) vertChange = 15.0;
			char.dy += animDiff * gravity;
			
			var horizChange = 0;
			var newAnimState:String = "sit";
			var newDirection:int = char.direction;
			
			if (char.moveLeft) {
				horizChange = -char.walkSpeed * animDiff;
				newAnimState = "run";
				newDirection = -1;
			} else if (char.moveRight) {
				horizChange = char.walkSpeed * animDiff;
				newAnimState = "run";
				newDirection = 1;
			}
			
			if (char.jump) {
				char.jump = false;
				char.dy = -char.jumpSpeed;
				vertChange = -char.jumpSpeed;
				newAnimState = "jump";
			}
			
			if (allen.isMoving == false && allen.sit == false) {
				newAnimState = "stand";
			}
						
			if (allen.isMoving == false && idleTime > 3){
				allen.sit = true;
				allen.animstate = "sit";
			}
			
			char.hitWallRight = false;
			char.hitWallLeft = false;
			char.inAir = true;
			
			//tells the game what tiles allen interacts with up and down.
			//allows allen to go through the bottom of floor tiles but not wall tiles
			//does not allow allen to go through the top of floor tiles
			var newY:Number = char.mc.y + vertChange;
			
			for (var i:int=0;i<floorObjects.length;i++) {
				if ((char.mc.x + char.width / 2 > floorObjects[i].leftside) && (char.mc.x - char.width / 2 < floorObjects[i].rightside)) {
					if ((char.mc.y <= floorObjects[i].topside) && (newY > floorObjects[i].topside)) {
						newY = floorObjects[i].topside;
						char.dy = 0;
						char.inAir = false;
						break;
					}
				}
			}
			
			for (var j:int=0;j<wallObjects.length;j++) {
				if ((char.mc.x + char.width / 2 > wallObjects[j].leftside) && (char.mc.x - char.width / 2 < wallObjects[j].rightside)) {
					if ((char.mc.y - char.height >= wallObjects[j].bottomside) && (newY - char.height < wallObjects[j].bottomside)) {
						newY = wallObjects[j].bottomside + char.height;
						char.dy = 0;
						char.inAir = true;
						break;
					}
				}
			}
			
			//tells the game what tiles allen interacts with left and right
			//allows allen to go through floor tiles but not wall tiles
			var newX:Number = char.mc.x + horizChange;
			
			for (i=0;i<wallObjects.length;i++) {
				if ((newY > wallObjects[i].topside) && (newY - char.height < wallObjects[i].bottomside)) {
					if ((char.mc.x - char.width / 2 >= wallObjects[i].rightside) && (newX - char.width / 2 <= wallObjects[i].rightside)) {
						newX = wallObjects[i].rightside + char.width / 2;
						char.hitWallLeft = true;
						break;
					}
					if ((char.mc.x + char.width / 2 <= wallObjects[i].leftside) && (newX + char.width / 2 >= wallObjects[i].leftside)) {
						newX = wallObjects[i].leftside - char.width / 2;
						char.hitWallRight = true;
						break;
					}
				}
			}
			
			char.mc.x = newX;
			char.mc.y = newY;
			
			if (char.inAir) {
				newAnimState = "jump";
			}
			
			//sets allens animation state
			char.animstate = newAnimState;
			
			if (char.animstate == "run") {
				char.animstep += animDiff / 60;
				if (char.animstep > char.walkAnimation.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.walkAnimation[Math.floor(char.animstep)]);
			
			} else if (char.animstate == "stand") {
				char.animstep += animDiff / 60;
				if (char.animstep > char.standAnimation.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.standAnimation[Math.floor(char.animstep)]);
			
			} else if (char.animstate == "sit") {
				char.animstep += animDiff / 60;
				if (char.animstep > char.sitAnimation.length) {
					char.animstep = 0;
				}
				char.mc.gotoAndStop(char.sitAnimation[Math.floor(char.animstep)]);
				
			} else {
				char.mc.gotoAndStop(char.animstate);
			}
			
			if (newDirection != char.direction) {
				char.direction = newDirection;
				char.mc.scaleX = char.direction;
			}
		}
		
		//makes the back ground scroll when allen moves to give the illusion of movement.
		public function scrollWithAllen() {
			var stageXPosition:Number = gamelevel.x + allen.mc.x;
			var stageYPosition:Number = gamelevel.y + allen.mc.y;
			var rightEdge:Number = stage.stageWidth - edgeXDistance;
			var leftEdge:Number = edgeXDistance;
			var topEdge:Number = stage.stageHeight - edgeYDistance;
			var bottomEdge:Number = edgeYDistance;
			
			//x position scrolling
			if (stageXPosition > rightEdge) {
				gamelevel.x -= (stageXPosition - rightEdge);
				if (gamelevel.x < -(gamelevel.width - stage.stageWidth)) {
					gamelevel.x = -(gamelevel.width - stage.stageWidth);
				}
			}
			
			if (stageXPosition < leftEdge) {
				gamelevel.x += (leftEdge - stageXPosition);
				if (gamelevel.x > 0) {
					gamelevel.x = 0;
				}
			}
			
			//y position scrolling
			if (stageYPosition > topEdge) {
				gamelevel.y -= (stageYPosition - topEdge);
				if (gamelevel.y < -(gamelevel.height - stage.stageHeight)) {
					gamelevel.y = -(gamelevel.height - stage.stageHeight);
				}
			}
			
			if (stageYPosition < bottomEdge) {
				gamelevel.y += (bottomEdge - stageYPosition);
				if (gamelevel.y > 0) {
					gamelevel.y = 0;
				}
			}
			
			//scrolls the clouds at a different rate than the back ground to 
			//give the illusion of parallax and adds depth to the level
			if (gamelevel.sky != null){
			gamelevel.sky.x = (gamelevel.x * -0.2)+((gamelevel.width/2)-(gamelevel.sky.width/2));
			gamelevel.sky.y = (gamelevel.y * -0.2)+((gamelevel.height/2)-(gamelevel.sky.height/2));
				if (allen.mc.y <= 0) {
					gamelevel.sky.y = gamelevel.sky.y;
				}
			}
		}

		//tests the level to see if allen is touching any collectable objects
		public function checkCollisions() {
			for (var i:int=otherObjects.length-1;i>=0;i--) {
				if (allen.mc.hitTestObject(otherObjects[i])) {
					getObject(i);
				}
			}
		}

		//tests the level to see if allen has reached stan
		public function monitorStan() {
			for (var i:int=stanObjects.length-1;i>=0;i--) {
				if (allen.mc.hitTestObject(stanObjects[i])) {
					hitStan(i);
				}
			}
		}
		
		//plays sound on event
		public function playSound(soundObject:Object) {
			var channel:SoundChannel = soundObject.play();
		}

		//depending on what object was hit update scores and play animation
		//updates number of objects left and collected
		public function getObject(objectNum:int) {
			
			if (otherObjects[objectNum] is Bone) {
				bonesLeft--;
				bonesCollected++;
				addScore(1);
				goodScore.x = gamelevel.x + allen.mc.x; 
				goodScore.y = gamelevel.y + allen.mc.y - (allen.mc.height); 
				goodScore.scaleX = .1;
				goodScore.scaleY = .1;
				addChild(goodScore);
				goodPoints();
				gamelevel.removeChild(otherObjects[objectNum]);
				otherObjects.splice(objectNum,1);
				
			} else if (otherObjects[objectNum] is Banana) {
				collectedABanana = true;
				bananasCollected++;
				addScore(-4);
				badScore.x = gamelevel.x + allen.mc.x;
				badScore.y = gamelevel.y + allen.mc.y - (allen.mc.height);
				badScore.scaleX = .1;
				badScore.scaleY = .1;
				addChild(badScore);
				badPoints();
				gamelevel.removeChild(otherObjects[objectNum]);
				otherObjects.splice(objectNum,1);
			
			} else if (otherObjects[objectNum] is Secret || otherObjects[objectNum] is Cloud) {
				otherObjects[objectNum].alpha = .5;
			}
		}
		
		//calls animation for points
		public function goodPoints() {
			goodPointsStep = 0;
			playSound(goodSound);
			this.addEventListener(Event.ENTER_FRAME, good);
		}
		
		//animates points
		public function good(event:Event) {
			goodPointsStep++;
			
			if (goodPointsStep < 10) {
				goodScore.scaleY = .1 * goodPointsStep;
				goodScore.scaleX = .1 * goodPointsStep;
				goodScore.alpha = 1 - (goodPointsStep/10);
				
			}
						
			if (goodPointsStep == 10) {
				removeChild(goodScore);
				this.removeEventListener(Event.ENTER_FRAME, good);
			}
		}

		//calls animation for points
		public function badPoints() {
			badPointsStep = 0;
			playSound(badSound);
			this.addEventListener(Event.ENTER_FRAME, bad);
		}
		
		//animates points
		public function bad(event:Event) {
			badPointsStep++;
			
			if (badPointsStep < 10) {
				badScore.scaleY = .1 * badPointsStep;
				badScore.scaleX = .1 * badPointsStep;
				badScore.alpha = 1 - (badPointsStep/10);
			}
						
			if (badPointsStep == 10) {
				removeChild(badScore);
				this.removeEventListener(Event.ENTER_FRAME, bad);
			}
		}
		
		//if stan is hit player either ends the level or has to retry
		public function hitStan(objectNum:int) {
			if (stan.animstate == "gone") {
				retry();
			} else if (stanObjects[objectNum] is Stan) {
				if (bonesLeft == 0) {
					collectedAllBones = true;
				}
				levelComplete();			
			}
		}

		//updates player score box
		public function addScore(numPoints:int) {
			gameScore += numPoints;
			scoreDisplay.text = String(gameScore); 
		}
		
		//if player failed to get to stan in time, has to retry
		//adds retry dialog and waits for enter
		public function retry() {
			gameMusicChannel.soundTransform = volumeDown;
			playSound(retrySound);
			cFrame = currentFrame;	
			
			gameMode = "done";
			
			retryDialog.x = 320;
			retryDialog.y = 240;
			addChild(retryDialog);
			removeChild(MovieClip(root).levelTime);
			
			if (gameMode == "done") {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
				stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
				
				stage.addEventListener(KeyboardEvent.KEY_DOWN,enterRetry);
			}
		}

		//if player completes level successfully, finds what acheivements the player has made
		//adds the level complete dialog and updates score info within
		//looks for save file and either creates one or updates one
		//checks for high score and allows player input to update
		public function levelComplete() {
			gameMusicChannel.soundTransform = volumeDown;
			if (collectedAllBones == true && collectedABanana == false) {
				allBonesBonus = levelBonus;
				dialog.allBonesBonusText.textColor = 0xFFFF00;
				dialog.allBonesBonusText.text = String(-levelBonus);
				dialog.gotBonusText.alpha = 1;
				playSound(allBonesSound);
			} else {
				dialog.allBonesBonusText.textColor = 0xFFFFFF;
				dialog.allBonesBonusText.text = "0";
				dialog.gotBonusText.alpha = 0;
			}
			gameMode = "done";
			dialog.x = 320;
			dialog.y = 240;
			addChild(dialog);
			removeChild(MovieClip(root).levelTime);
			totalScore = platformGameTime - gameScore - allBonesBonus;
			dialog.message.text = "You caught up to Stan!";
			dialog.bonesText.text = String(-bonesCollected);
			dialog.bananasText.text = String(bananasCollected*4);
			dialog.levelScoreText.text = String(-(gameScore + allBonesBonus));
				if (-(gameScore + allBonesBonus) > 0) {
					dialog.levelScoreText.textColor = 0xC80500;
				}
				if (-(gameScore + allBonesBonus) < 0) {
					dialog.levelScoreText.textColor = 0x0BC8F5;
				}
				if (-(gameScore + allBonesBonus) == 0) {
					dialog.levelScoreText.textColor = 0xFFFFFF;
				}
			dialog.bonesCollectedText.text = String(bonesCollected) + " of " + String(bonesTotal);
			dialog.bananasCollectedText.text = String(bananasCollected) + " of " + String(bananasTotal);
			dialog.levelTimeText.text = String(platformGameTime.toFixed(3));
			dialog.levelFinalTime.text = String(totalScore.toFixed(3));
			
			if (gameMode == "done") {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN,keyDownFunction);
				stage.removeEventListener(KeyboardEvent.KEY_UP,keyUpFunction);
			}
			
			saveData = SharedObject.getLocal("level"+(currentFrame-5)+"highscore");
			
			if(saveData.data.savedScore == null){
				saveData.data.savedScore = totalScore.toFixed(3);
				dialog.highScoreText.text = "You got the best time! Enter your initials:";
				dialog.newHSText.alpha = 1;
				playSound(highScoreSound);
				setHS();
				
     		} else if (totalScore <= saveData.data.savedScore) {
				saveData.data.savedScore = totalScore.toFixed(3);
				levelHighScore = totalScore;
				dialog.highScoreText.text = "You got the best time! Enter your initials:";
				dialog.newHSText.alpha = 1;
				playSound(highScoreSound);
				setHS();
				
     		} else if (totalScore > saveData.data.savedScore) {
				dialog.highScoreText.text = "Come back again to try for the best time!";
				dialog.newHSText.alpha = 0;
				dialog.myInput.background = false;
				dialog.myInput.border = false;
				dialog.myInput.text = "";
				stage.addEventListener(KeyboardEvent.KEY_DOWN,enterNext);
			}
			
			dialog.highScore.text = saveData.data.savedScore.toString();
		}
		
		//creates input for the player to put initials in for a high score
		public function setHS() {
			dialog.myInput.maxChars = 3;
			dialog.myInput.restrict = "A-Z";
			dialog.myInput.text = " ";
			dialog.myInput.multiline = false;
			dialog.myInput.background = true;
			dialog.myInput.border = true;
			dialog.myInput.backgroundColor = 0x996600;
			stage.focus = dialog.myInput;
			dialog.myInput.setSelection(0,0);
			dialog.myInput.text = "";
			stage.addEventListener(KeyboardEvent.KEY_DOWN,checkForReturn);
		}
			
		//listens for enter only if input box is not empty
		public function checkForReturn(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				if (dialog.myInput.text != "") {
					stage.removeEventListener(KeyboardEvent.KEY_DOWN,checkForReturn);
					acceptInput();
				}
			}
		}
		
		//sets up game to go to next level
		public function acceptInput() {
			var theInputText:String = dialog.myInput.text;
			saveData.data.hsName = theInputText;
			saveData.flush();
			dialog.myInput.text = ""
			cFrame = currentFrame + 1;
			removeChild(dialog);
			gameMusicChannel.stop();
			cleanUp();
		}

		//if player is to retry sets up game to reset the current level
		public function enterRetry(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				gamelevel.removeChild(dustGone);
				removeChild(retryDialog);
				gameMusicChannel.stop();
				retryCleanUp();
			}
		}
		
		//resets level parameters ready for player to restart the current level
		public function retryCleanUp() {
			collectedABanana = false;
			collectedAllBones = false;
			allBonesBonus = 0;
			bonesLeft = 0;
			bonesTotal = 0;
			bonesCollected = 0;
			bananasCollected = 0;
			bananasTotal = 0;
			dustStep = 0;
			scaleIncrement = 0.25;
			MovieClip(root).platformGameTime = platformGameTime;
			MovieClip(root).platformStartTime = platformStartTime;
			MovieClip(root).gameScore = gameScore;
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,enterRetry);
			stage.removeEventListener(Event.ENTER_FRAME,gameLoop);
			removeChild(gamelevel);
			cFrame = currentFrame;
			gotoAndStop("countdownP");
		}
		
		//waits for input to clean up for next level
		public function enterNext(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				removeChild(dialog);
				gameMusicChannel.stop();
				cFrame = currentFrame + 1;
				cleanUp();
			}
		}		
		
		
		//resets parameters for game to advance to correct frame
		//able to go to specific frame depending on what call this function
		//goes to main menu if called from pause menu or player completes level 10
		//without completing all others before it in a row
		//if player completes all levels in a row goes to the complete screen
		//if player completes a level advences to the next level through the countdown screen
		public function cleanUp() {
			collectedABanana = false;
			collectedAllBones = false;
			allBonesBonus = 0;
			bonesLeft = 0;
			bonesTotal = 0;
			bonesCollected = 0;
			bananasCollected = 0;
			bananasTotal = 0;
			dustStep = 0;
			scaleIncrement = 0.25;
			MovieClip(root).platformGameTime = platformGameTime;
			MovieClip(root).platformStartTime = platformStartTime;
			MovieClip(root).gameScore = gameScore;
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,enterNext);
			stage.removeEventListener(Event.ENTER_FRAME,gameLoop);
			stage.focus = stage;
			removeChild(gamelevel);
			levelsCompleted++;
			if (cFrame == 4) {
				levelsCompleted = 0;
				gotoAndStop("start");
			} else if (levelsCompleted != 10 && currentFrame == 15) {
				startChannel = startThemeSound.play(0,10);
				levelsCompleted = 0;
				gotoAndStop("start");
			} else if (levelsCompleted == 10) {
				gotoAndStop("complete");
			} else {
				gotoAndStop("countdownP");
			}
		}
	}
}
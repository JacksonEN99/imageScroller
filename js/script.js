class Slides {
	constructor (transitionTime, timer) {
		//Adjustable Settings
		this.opacityIncrement = 0.01;
		this.incrementSpeed = 20;
		this.paddedIncrement = 100; // This just addes additional time (milli-seconds) between each setTimeOut() functions in the start() function.
		this.incrementTime = (1 / this.opacityIncrement) * this.incrementSpeed + this.paddedIncrement;
		this.timer = timer;
		this.transitionTime = transitionTime;
		
		//Other Settings
		this.slides = document.querySelectorAll('.flex-container');
		this.increaseCurrentOpacitytInterval = null;
		this.decreaseCurrentOpacityInterval = null;
		this.increaseNextOpacitytInterval = null;
		this.decreaseNextOpacityInterval = null;
		this.currentIndex = 0;
		this.nextIndex = 0;
	};
	
	// Current images being shown
	currentImages() {
		this.slides[this.currentIndex].style.display = "flex";
		this.slides[this.currentIndex].style.opacity = 0;
		this.increaseCurrentOpacityInterval = setInterval(this.increaseCurrentOpacity.bind(this), this.incrementSpeed);
	};
	
	// Next list of images in the queue
	nextImages() {
		if(this.currentIndex + 1 >= this.slides.length) {
			this.nextIndex = 0;
		} else {
			this.nextIndex = this.currentIndex + 1;
		}
		this.slides[this.nextIndex].style.display = "flex";
		this.slides[this.nextIndex].style.opacity = 0;
		this.slides[this.nextIndex].classList.add('moveUp');
		this.increaseNextOpacityInterval = setInterval(this.increaseNextOpacity.bind(this), this.incrementSpeed);
	};
	
	// Gradually increase the opacity of the currently shown images
	increaseCurrentOpacity() {
 		let opacity = parseFloat(this.slides[this.currentIndex].style.opacity);
		if(opacity < 1) {
			opacity += this.opacityIncrement;
			this.slides[this.currentIndex].style.opacity = opacity;
		} else {
			clearInterval(this.increaseCurrentOpacityInterval);
		}
	};
	
	// Gradually decrease the opacity of the currently shown images
	decreaseCurrentOpacity() {
		let opacity = parseFloat(this.slides[this.currentIndex].style.opacity);
		if(opacity > 0) {
			opacity -= this.opacityIncrement;
			this.slides[this.currentIndex].style.opacity = opacity;
		} else {
			clearInterval(this.decreaseCurrentOpacityInterval);
			this.slides[this.currentIndex].style.display = "none";
		}
	};
	
	// Gradually increase the opacity of the next images in the queue
	increaseNextOpacity() {
		let opacity = parseFloat(this.slides[this.nextIndex].style.opacity);
		if(opacity < 1) {
			opacity += this.opacityIncrement;
			this.slides[this.nextIndex].style.opacity = opacity;
		} else {
			clearInterval(this.increaseNextOpacityInterval);
		}
	};

	// Gradually decrease the opacity of the next images in the queue
	decreaseNextOpacity() {
		let opacity = parseFloat(this.slides[this.nextIndex].style.opacity);
		if(opacity > 0) {
			opacity -= this.opacityIncrement;
			this.slides[this.nextIndex].style.opacity = opacity;
		} else {
			clearInterval(this.decreaseNextOpacityInterval);
			this.slides[this.nextIndex].classList.remove('moveUp');
			this.slides[this.nextIndex].style.display = "none";
		}
	};
	
	// Changes when 'currentImages()' images are shown and when 'nextImages()' images are shown
	increaseIndex() {
		if(this.nextIndex + 1 < this.slides.length) {
			this.currentIndex = this.nextIndex + 1;
		} else {
			this.currentIndex = 0;
		}
	};
	
	setTransTime(input) {
		this.transitionTime = input;
	};
	
	setTimer(input) {
		this.timer = input;
	};
	
	// Clear/reset all the settings for 'currentImage()' images
	// Needed to stop 'currentImages()' from showing up at the same time as 'nextImages()'
	clearCurrentImage() {
		clearInterval(this.increaseCurrentOpacityInterval);
		clearInterval(this.decreaseCurrentOpacityInterval);
		this.slides[this.currentIndex].style.display = "none";
		this.slides[this.currentIndex].style.opacity = 0;
		this.slides[this.currentIndex].classList.remove('moveUp');
	};

	// Clear/reset all the settings for 'nextImage()' images
	// Needed to stop 'nextImages()' from showing up at the same time as 'currentImages()'
	clearNextImage() {
		if (this.increaseNextOpacityInterval) {
			clearInterval(this.increaseNextOpacityInterval);
			clearInterval(this.decreaseNextOpacityInterval);
			this.slides[this.nextIndex].style.display = "none";
			this.slides[this.nextIndex].style.opacity = 0;
			this.slides[this.nextIndex].classList.remove('moveUp');
		}
	};
	
	start() {
		this.currentImages();

		setTimeout(() => {
			this.decreaseCurrentOpacityInterval = setInterval(this.decreaseCurrentOpacity.bind(this), this.incrementSpeed);
		}, this.timer + this.incrementTime);

 		setTimeout(() => {
			this.clearNextImage();
			this.nextImages();
		}, this.timer + this.transitionTime + this.incrementTime);

		setTimeout(() => {
			this.decreaseNextOpacityInterval = setInterval(this.decreaseNextOpacity.bind(this), this.incrementSpeed);
		}, (this.timer + this.incrementTime) * 2 + this.transitionTime);

		setTimeout(() => {
			this.clearCurrentImage();
			this.increaseIndex();
		}, (this.timer + this.incrementTime + this.transitionTime) * 2 - this.paddedIncrement);

		setTimeout(() => {
			this.start();
		}, (this.timer + this.incrementTime + this.transitionTime) * 2);
	};
}

const slide = new Slides(500, 3500);
slide.start();

const transitionTimeSlider = document.querySelector("#transitionTimeSlider");
const transitionTimeSpan = document.querySelector("#transitionTimeSpan");
transitionTimeSlider.value = slide.transitionTime;
transitionTimeSpan.innerHTML = transitionTimeSlider.value/1000;

transitionTimeSlider.oninput = function() {
  transitionTimeSpan.innerHTML = this.value/1000;
};
transitionTimeSlider.onchange = function() {
	slide.setTransTime(parseInt(this.value));
};

const viewTimeSlider = document.querySelector("#viewTimeSlider");
const viewTimeSpan = document.querySelector("#viewTimeSpan");
viewTimeSlider.value = slide.timer;
viewTimeSpan.innerHTML = viewTimeSlider.value/1000;

viewTimeSlider.oninput = function() {
	viewTimeSpan.innerHTML = this.value/1000;
};
viewTimeSlider.onchange = function() {
	slide.setTimer(parseInt(this.value));
};
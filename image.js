//
// WASM_3_IMAGE_PIXELS_VIEW
// by Gounbeee 2022
//
// :: FOR SPRITE ANIMATION WE WILL CLIP LARGE IMAGE WHICH INCLUDES
//    


// -------------------------------------------------------------------
// IMAGE
//                           384 px
// =============================
// |         |        |
// |    1    |    2   |    3
// |	     |   	  |
// |	     |		  |
// =============================
//     32 px    32px 
//
//  **** 1px -> 4 channels INCLUDED　! 
//  SO ACTUAL AMOUNT OF BYTES FOR 1 ROW WOULD BE < PIXEL COUNT * 4 >
//


// IMAGE SETTINGS
const width_src = 384;
const height_src = 32;

const allCntSprite = 12;
const channels_pixel = 4; 							// RGBA


// CANVAS SETTINGS
const canvas_src = document.getElementById("cnvs_source");

const canvas = document.getElementById("cnvs");




// SETTING CANVAS
canvas_src.width = width_src;
canvas_src.height = height_src;




// ---------------------------------------------------------------------------
// PREPARING WASM MEMORY 
const memory = new WebAssembly.Memory({ initial: 4 }); 		// 5120000 BYTES = 5 MB




// ---------------------------------------------------------------------------
// LOADING IMAGE

console.log("loadSrcImage() FUNCTION EXECUTED !!");
loadSrcImage(canvas_src, 'char_01.png', 0, 0, width_src, height_src, main);



function main(imageDt) {

	console.log("main() FUNCTION EXECUTED !!");
	console.log(`PARAMETER : ${imageDt}`);
	console.log(imageDt.data);
	console.log(imageDt.data.length);



	// PREPARE IMPORT OBJECT FOR WASM MODULE
	const importObject = {
		env: {
			log: (value1, value2) => {console.log("WASM IS LOGGING ...    :: ", value1, "  ::  ", value2);},
			buffer: memory,
			cnvs_width: canvas.width,
			cnvs_height: canvas.height,
			cnvs_src_width: width_src,
			cnvs_src_height: height_src,
		}
	};


	// ---------------------------------------------------
	// JS CAN ACCESS WASM WITH THIS 'INSTANTIATING' OBJECT
	(async () => {


		let obj = await WebAssembly.instantiateStreaming(fetch('imageViewer.wasm'), importObject)
		.then( (module) => {
			
			// ----------------------------------------------------------
			// GETTING FUNCTION AND MEMORY ARRAYBUFFER FROM WASM MODULE
			let {getSpriteImg, memory} = module.instance.exports;

			// CHECKING WASM EXPORT
			console.log(getSpriteImg)
			console.log(memory.buffer)


			let imageCnt = 0;

			// SIMPLE ANIMATION
			setInterval( () => {
				//console.log(imageCnt);

				displaySprite(memory, getSpriteImg, imageDt, width_src, height_src, canvas, canvas.width, canvas.height, channels_pixel, allCntSprite, imageCnt);
				imageCnt++;
				imageCnt = imageCnt % allCntSprite; 			// LOOPING VALUE


			}, 60 );

		});

	})();

}




// ------------------------------------------------------------------------------------




function displaySprite(wasmMem, getSpriteImg, sourceImgDt, width_src, height_src, canvas_tar, width_tar, height_tar, channels_pixel, allCntSprite, spriteNum) {


	const pixel_count = width_src * height_src;


	// ----------------------------------------------------------
	// DESIGNING MEMORY ALLOCATION 
	let offset = 0;

	let allPixelsArray = new Int32Array(wasmMem.buffer, 0, pixel_count*channels_pixel);		// 49152 BUFFERS
	allPixelsArray.set(sourceImgDt.data)
		
	// SETTING NEXT STARTING POINT IN THE MEMORY
	offset += pixel_count * channels_pixel * Int32Array.BYTES_PER_ELEMENT


	// SETTING NEW MEMORY ARRAYBUFFER FOR RESULT IMAGE (CLIPPED IMAGE)
	let sprImageArr = new Int32Array(wasmMem.buffer, offset, width_tar * height_tar * channels_pixel);


	// ----------------------------------------------------------
	// EXECUTE FUNCTION OF WASM MODULE
	getSpriteImg(allPixelsArray.byteOffset, width_src, height_src, width_tar, height_tar, spriteNum, allCntSprite, sprImageArr.byteOffset);


	//console.log(`[${sprImageArr.join(", ")}]`);
	// console.log("**** sprImageArr IS...");
	// console.log(sprImageArr);
	// console.log(sprImageArr.byteOffset); 				// Offset !!!!! O !!! NOT o !!!!
	// console.log(sprImageArr.length);

	let convArr = new Uint8ClampedArray(sprImageArr);
	// console.log("**** convArr IS...");
	// console.log(convArr);
	// console.log(convArr.byteOffset); 					// Offset !!!!! O !!! NOT o !!!!
	// console.log(convArr.length);

	let clippedImg = new ImageData(convArr, width_tar, height_tar);

	// DISPLAY IMAGE
	let ctx = canvas_tar.getContext('2d');
	ctx.putImageData(clippedImg, 0, 0);


	// MEMORY RELEASING --> THIS IS JUST SAMPLE CASE !
	allPixelsArray = null;
	sprImageArr = null;
	convArr = null;
	clippedImg = null;

}



function loadSrcImage(canvas, src, x, y, width, height, opt_callback) {
    var img = new window.Image();
    img.crossOrigin = '*';
    img.src = src;

    img.onload = function () {
	    context = canvas.getContext('2d');
	    canvas.width = width;
	    canvas.height = height;
	    context.drawImage(img, x, y, width, height);

	    const imageData = context.getImageData(0, 0, width, height);
	    console.log(imageData);

	    // PASS THIS OBEJECT (Image OBJECT) TO CALLBACK FUNCTION
	    opt_callback && opt_callback(imageData);

	    img = null;
    };
}




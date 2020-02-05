# Downsampling images for better memory consumption and UICollectionView performance


"Anything that can go wrong will go wrong".<br/>
Murphy's law


At each step of the development, we make architectural decisions that affect the overall performance of the app. We all know very well that the power usage and memory consumption are extremely important for the mobile application. We also know that there some kind of correlation between the available free memory and the relative performance of the app. But in today's world of quick solutions, shortened deadlines and spirit of avoiding premature optimization so easy to miss important things. Let's take a look at a common task - image gallery. It may look different way with various image layouts. But the thing they have in common - a batch of images that displayed on the screen at the same time.

<img src="/images/image6.png" width="350">

#### The problem definition

Let’s say you've decided to take the downloaded image from the server and display it in an `UIImageView`. Nothing wrong with this approach at all. Moreover, [Apple recommends](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/LoadingImages/LoadingImages.html#//apple_ref/doc/uid/TP40010156-CH17-SW7) using `UIImage` and `UIImageView` to display the image in all common cases. The exception only if you have some specific image processing.

Let's return to gallery. Probably you’ve tested the application on different image sets using Simulator and latest iPhone version. And now ready for QA stage. Beta-testers and QA engineers picking up your application and then you see this strange-looking crash reports:

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image7.png)

You are starting to test your app with a specific image set and see this:  

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image5.png)

Virtually every WWDC session dedicated to the performance best practices say that iOS application should use as little memory as possible. Memory is the most constrained resource on iOS. The System may ask for free memory faster than it could be released. As says [the documentation](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/ManagingMemory/Articles/AboutMemory.html) and this WWDC [session](https://developer.apple.com/videos/play/wwdc2018/416/) iOS does not have the traditional disk swap, instead it use the memory compressor technic.

An average user has more than one application on his device. A lot of applications still may be in the background and continue to consume some memory. Some part of the memory the System itself is consuming. At this point, you may consider there still should be left enough memory to run your application smoothly. Anyway, iOS is smart enough to unload one or two annoying memory consumers. But in reality, the System set the memory limit, which each application can consume. The running in foreground application could be shut down because of limit overrun.  

So why images could lead to such consequences? 

#### Image rendering flow

The most common way do display an image in iOS is to use `UIImageView` and `UIImage`. `UIImage` class is responsible for managing image data, transformations, applying the proper scale factor. `UIImageView` - for displays an image in app interface.

On the WWDC session: [Image and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219/) engineers from Apple offered a very simple and visual diagram of how it actually works. Based on it when you are using `UIImage` for drawing an image in `UIImageView` it actually takes a few steps:

1.  Load compressed image data to memory. 
2.  Convert compressed image data to the format, which rendering system can understand.
3.  Render decoded image.


![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image3.png)

Let’s make a stop here. We need to understand what the image is, what kind and formats of images do we have and how does the stored.

#### Image types

First of all, there are 2 main types of images: raster (bitmap) and vector. Raster image represented as a rectangular grid filled by the encoded individual value of each pixel. The vector image is defined in terms of 2D points, connected by lines, polygons and other shapes. Unlike raster, vector formats store instructions for drawing an image.

Raster and Vector images have their own set of pros and cons and usually used for different purposes. Vector usually used for images that will be applied on a physical product, logos, technical drawings, text, icons, something which contains sharp geometric shapes. The main advantage of a vector image is resolution independence. This means scalability without losing sharpness and quality. Vector images use mathematical calculations from one point to another that form lines and shapes, that’s why it produces the same result for every resolution and zoom.

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image9.png)

Raster image consists of a particular amount of pixels. When you zoom raster image it becomes blurry and jagged. But raster image works better with a complicated scene like photos. Photo editing, for example, is better with a raster image. This happens because raster images use a large number of pixels of different colors. By changing the color of each pixel different shades and gradation can be reached.

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image4.png)

Origin image by [Printeboek](https://pixabay.com/photos/spring-blossom-flowers-pink-nature-2854205/) on Pixabay  

#### Image compression

Next step is compression, which is a broad topic. Therefore, we denote only some points that are important in the current context. The aim of compression is a redundancy of the image data for storage and transmission purposes. Two types of image compression are used for the coding of images:

- lossless (reversible) compression;
- lossy (irreversible) compression.

With lossless compression, the picture quality remains the same. The file can be decompressed to its original quality. Lossy compression permanently removes data and this process is irreversible. Which means that this way compressed image can’t be decompressed with original quality.

Most popular in iOS development image formats like PNG, JPEG is actually the raster images. SVG format (which is more popular on Android rather than iOS) is a vector image. As an example PNG is a lossless compression type, JPEG is lossy. Despite the difference in storage approaches, vector images can also be fairly large.

According to the [documentation](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/LoadingImages/LoadingImages.html#//apple_ref/doc/uid/TP40010156-CH17-SW7), iOS natively supports next image formats:

.png, .tiff or .tif, .jpeg or .jpg, .gif, .bmp or .BMPf, .ico, .cur, .xbm.

Actually all this graphics file formats is raster images. So let's restrict ourselves by compressed raster images.

#### Load compressed image data to memory

A buffer is a memory designated to contain data that is stored for a short amount of time for being worked on. As an example, the buffer is used for handling audio data. At first chunk of data being loaded to the buffer and player able to play it from this buffer while remaining to continue to load and append to the existing one. When `UIImage` loads an image, the compressed image data become loaded to the data buffer, which actually not describes image pixels.

Next concept is a framebuffer. The framebuffer is the final destination for rendering commands and graphics pipelines. It contains information about the data to be rendered. Renderer works with framebuffers. At this point, you may have a question of how compressed encoded image from data buffer become a proper per pixel information in a framebuffer, such that rendering mechanism could understand and apply.

#### Decoding. The theory

On the decode stage, compressed image data become uncompressed and decoded into the format which is understandable for GPU. Decoded data then placed to the image buffer, which contains an image data into per pixel image information. As we figured out earlier a raster image - is a collection of pixels. Each pixel represents a specific color. Thereby amount memory which will be allocated for the image buffer relates to the dimensions of the image.

Pixel color represented by one or more color components and additional component for alpha (based on color space). For example, in RGB color model there are 3 channels - red, green, blue. And 4 for RGBA, alpha is an additional channel which represent transparency. Read section [About Color Spaces](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/DrawColor/Concepts/AboutColorSpaces.html) to have more information about digital color theory.

The pixel format consists of the [following information:](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html)

-   Bits per component, which is the number of bits in each individual color component in a pixel.
-   Bits per pixel, which is the total number of bits in a source pixel. This value must be at least the number of bits per component times the number of components per pixel.
-   Bytes per row. The number of bytes per horizontal row in the image.    

32-bit pixel format for RGBA color spaces in Quartz 2D, taken from the official [documentation](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html):

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image1.png)

The [default color space on iOS](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/) is Standard RGB (sRGB) which produces 4 bytes per pixel. To calculate the size of the image buffer we need to take the size of single pixel color information in the particular color space and multiply on the total amount of pixels in the image. Let’s consider the real case. I took a JPG image, its resolution is 3024 x 4032, size is 3.1 MB. The amount of allocated memory in this case should be:

3024 * 4032 * 4 = 48771072 bytes = 46.51172 MB

Same calculation approach demonstrated on WWDC session [iOS Memory Deep Dive](https://developer.apple.com/videos/play/wwdc2018/416/), but that’s was the theory. Now we need to make the test on the real device to check does the memory allocation confirms above calculations for most popular on iOS raster image formats: PNG and JPG.

#### Decoding. The test

Initial data:

-   PNG image with 3024 * 4032 and file size 14.2 MB on disk
-   JPG image with 3024 * 4032 and file size 3.1 MB on disk (remember that JPG is lossy compressed image )
    

Test device:
-   iPhone XS (iOS 12.1.4)

Testing tools:
-   Allocations instrument
-   [Memory Graph Debugger](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/debugging_with_xcode/chapters/special_debugging_workflows.html)
-   [vmmap](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/ManagingMemory/Articles/VMPages.html) (display the virtual memory regions allocated for a specified process)
   
vmmap --summary ImagePerfomanceTest.memgraph

Memory consumption test result for PNG image:

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image12.png)
The allocation stack trace look next:

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image10.png)

So 14.2 MB PNG image of on-disk file size becomes 46.5 MB in virtual memory. Same results reproduced either on device and iOS simulator.

With JPG image things become tricker. On the iOS simulator, I’ve got the same memory consumption for JPG as for PNG (46.5 MB). But on a real device, I’ve got this:

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image13.png)
The allocation stack trace for JPG image:
![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image2.png)

As you can see the physical footprint and memory allocation stack trace are different. JPG with same image resolution requres less memory consumtion. Instead of expected 46.5 MB there is 17.6M in [IOSurface](https://developer.apple.com/documentation/iosurface).

 The results showed that image resolution is very important, but there is other things which affect memory footprint.

#### Downsampling

Let's complicate things a bit, imagine you are developing an app for the professional photographers and designers. They are uploading high-resolution images. Instead of 3024 x 4032 photo, you’ll load an image with 6000 x 4000 and larger for example. Now return to our gallery and display 10 - 20 such images on the screen at the same time. Even if your images will be placed in an `UIImageView` with small bounds, an image buffer for all these images will still beholden in memory while an `UIImage` which represent this image will alive.

Obviously we need to change our application to improve user experience and avoid app crash and our first step is downsampling. We have few options:
1.  For the preview purposes (like image thumbnails in gallery) download resized images and download the full image when used indeed need it. The reason is very clear - you don’t need a high-resolution 3000 x 4000 photo to display it in 100x100 bounds. Stock images sources, which has an API to work with, usually provide such functionality. The image URL looks something like this: `https://{ PATH_TO_IMAGE }/{ IMAGE_ID }_{ SIZE }.jpg.`

Same approach could be used on your custom server as well. Moreover, this approach gives you a few more benefits: download image faster, use less traffic. The last one is extremely important for users with limited mobile internet.

2. If you don’t have opportunities to download a downsampled image, you need to do it yourself. There the number of different approaches to resizing an image, but keep in mind that you need to do it without load the whole image into memory. Image rendering flow, in this case, will look like this:

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image11.png)


[CGImageSource](https://developer.apple.com/documentation/imageio/cgimagesource-r84) objects abstract the data-reading task, reduces the need to manage data through a raw memory buffer.  CGImageSource can load data from URL, a CFData object, or a data consumer.

The source code for downsampling an image listed below:

    private  func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {

    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!
   
    let maxDimentionInPixels = max(pointSize.width, pointSize.height) * scale
    
    let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels] as CFDictionary

    let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions)!
    return UIImage(cgImage: downsampledImage)    
    }

Here’s what the code does:

1.  Create a dictionary, that specifies image source creation options. In current version used [kCGImageSourceShouldCache](https://developer.apple.com/documentation/imageio/kcgimagesourceshouldcache). Despite the unobvious moment, this value indicates whether the image should be cached in a decoded form. When it set to false CoreGraphics keeps only stored in file data without immediate decoding it.
2.  Create an image source object from the passed URL.  
3.  Calculate maximum pixels (width or height) for [kCGImageSourceThumbnailMaxPixelSize](https://developer.apple.com/documentation/imageio/kcgimagesourcethumbnailmaxpixelsize?language=objc). This value calculates based on the desired thumbnail size and screen scale factor. 
4.  Create an options dictionary for the thumbnail creation. It contains next values:  
-   [kCGImageSourceCreateThumbnailFromImageAlways](https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailfromimagealways?language=objc) -  indicates whether a thumbnail should be created from the full image even if a thumbnail is present in the image source file. Bevare that is this key specified to true, but kCGImageSourceThumbnailMaxPixelSize is not set - CoreGraphics will create a thumbnail with size of full image.
    
-   [kCGImageSourceShouldCacheImmediately](https://developer.apple.com/documentation/imageio/kcgimagesourceshouldcacheimmediately) - the documentation isn't very eloquent about this parameter. But on WWDC session: Image and [Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219/) was mentioned that by passing this option `true` we are telling CoreGraphics that thumbnail creation is exact moment to create a decoded image buffer for it.
    
-   [kCGImageSourceCreateThumbnailWithTransform](https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailwithtransform?language=objc) - indicates that the thumbnail should be rotated and scaled according to the orientation and pixel aspect ratio of the full image.
    
-   [kCGImageSourceThumbnailMaxPixelSize](https://developer.apple.com/documentation/imageio/kcgimagesourcethumbnailmaxpixelsize?language=objc) - the maximum width and height in pixels of a thumbnail. If this key is not specified, the width and height of a thumbnail is not limited and thumbnails may be as big as the image itself.
    

5. Creates a `CGImage` thumbnail image of the image located at a specified location in an image source. An image source can contain more than one image, thumbnail images, properties for each image, and the image file. In this case, we specified index 0 because we know that there is only one image.
6. Convert CGImage to UIImage.

More information about this technique you can find in the documentation section [Creating and Using Image Sources](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/ImageIOGuide/imageio_source/ikpg_source.html) and WWDC session: [Image and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219/).

![](https://github.com/SezorusArticles/Article_KZ004/blob/master/images/image8.png)

Memory significantly consumption improved.

  

For the better user experience and smooth scrolling, it makes sense to:
- use images that don’t need resizing and downsampling when possible;
- decode images for collection view cells before they are displayed (Prefetching Collection View Data );
- cache downsampled versions of frequently used images;
- make your `UIImageView` opaque whenever possible;
- use JPEG for photos by finding a compromise between quality and compression level.

  

The demo with collection view based gallery, downsampling images technique and prefetching Collection View Data available [here](https://github.com/SezorusArticles/Article_KZ004).

  

Thank you for your time.

#### Author

Kseniia Zozulia

Email:  [kseniiazozulia@sezorus.com](mailto:kseniiazozulia@sezorus.com)

LinkedIn:  [Kseniia Zozulia](https://www.linkedin.com/in/629bb187)

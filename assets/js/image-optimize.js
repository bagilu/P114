const MB=1024*1024;

function canvasBlob(canvas,type,quality){
  return new Promise((resolve,reject)=>{
    canvas.toBlob(blob=>blob?resolve(blob):reject(new Error("IMAGE_ENCODE_FAILED")),type,quality);
  });
}

async function decodeImage(file){
  if("createImageBitmap" in window){
    try{return await createImageBitmap(file,{imageOrientation:"from-image"});}catch{}
    try{return await createImageBitmap(file);}catch{}
  }
  return await new Promise((resolve,reject)=>{
    const url=URL.createObjectURL(file),img=new Image();
    img.onload=()=>{URL.revokeObjectURL(url);resolve(img)};
    img.onerror=()=>{URL.revokeObjectURL(url);reject(new Error("IMAGE_DECODE_FAILED"))};
    img.src=url;
  });
}

function dims(source){
  return {
    width:source.width||source.naturalWidth||0,
    height:source.height||source.naturalHeight||0
  };
}

function targetSize(width,height,maxLongEdge){
  const long=Math.max(width,height);
  if(!long||long<=maxLongEdge)return{width,height};
  const scale=maxLongEdge/long;
  return{width:Math.max(1,Math.round(width*scale)),height:Math.max(1,Math.round(height*scale))};
}

function renamedFile(blob,originalName){
  const base=(originalName||"photo").replace(/\.[^.]+$/,"").replace(/[^A-Za-z0-9._-]/g,"-")||"photo";
  return new File([blob],base+".jpg",{type:"image/jpeg",lastModified:Date.now()});
}

export function formatBytes(bytes){
  if(bytes>=MB)return(bytes/MB).toFixed(2)+" MB";
  if(bytes>=1024)return Math.round(bytes/1024)+" KB";
  return bytes+" B";
}

export async function optimizeImage(file,{targetBytes=MB,maxLongEdge=2048,minQuality=.55,startQuality=.86}={}){
  if(!file||!/^image\/(jpeg|png|webp)$/i.test(file.type||""))throw new Error("IMAGE_TYPE_NOT_SUPPORTED");
  const source=await decodeImage(file);
  const original=dims(source);
  if(!original.width||!original.height)throw new Error("IMAGE_DIMENSIONS_UNAVAILABLE");

  let size=targetSize(original.width,original.height,maxLongEdge);
  let best=null,quality=startQuality;

  for(let pass=0;pass<10;pass++){
    const canvas=document.createElement("canvas");
    canvas.width=size.width;canvas.height=size.height;
    const ctx=canvas.getContext("2d",{alpha:false});
    if(!ctx)throw new Error("IMAGE_CANVAS_UNAVAILABLE");
    ctx.fillStyle="#fff";ctx.fillRect(0,0,size.width,size.height);
    ctx.drawImage(source,0,0,size.width,size.height);

    quality=pass===0?startQuality:quality;
    for(let q=quality;q>=minQuality-.001;q-=.06){
      const blob=await canvasBlob(canvas,"image/jpeg",Math.max(minQuality,q));
      if(!best||blob.size<best.size)best=blob;
      if(blob.size<=targetBytes){
        if(source.close)source.close();
        return{
          file:renamedFile(blob,file.name),
          originalBytes:file.size,
          outputBytes:blob.size,
          originalWidth:original.width,
          originalHeight:original.height,
          outputWidth:size.width,
          outputHeight:size.height,
          quality:Math.max(minQuality,q),
          targetBytes
        };
      }
    }
    size={width:Math.max(640,Math.round(size.width*.86)),height:Math.max(640,Math.round(size.height*.86))};
    quality=Math.max(minQuality,startQuality-.12);
  }

  if(source.close)source.close();
  if(!best)throw new Error("IMAGE_ENCODE_FAILED");
  return{
    file:renamedFile(best,file.name),
    originalBytes:file.size,
    outputBytes:best.size,
    originalWidth:original.width,
    originalHeight:original.height,
    outputWidth:size.width,
    outputHeight:size.height,
    quality:minQuality,
    targetBytes,
    warning:best.size>targetBytes
  };
}

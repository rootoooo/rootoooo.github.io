<?php
error_reporting(0);
header("Content-Type:application/json;charset=utf-8");
function f_curl($url,$hdr,$data,$hosts,$ist){
    $ch=curl_init();
    curl_setopt($ch,CURLOPT_URL,$url);
    curl_setopt($ch,CURLOPT_SSL_VERIFYPEER,false);
    curl_setopt($ch,CURLOPT_SSL_VERIFYHOST,false);
    curl_setopt($ch,CURLOPT_RETURNTRANSFER,1);
    if($hdr!="") curl_setopt($ch,CURLOPT_HTTPHEADER,$hdr);
    if($data!="") curl_setopt($ch,CURLOPT_POSTFIELDS,$data);
    if($hosts!="") curl_setopt($ch,CURLOPT_RESOLVE,$hosts);
    if($ist==1) curl_setopt($ch,CURLOPT_HEADER,1);
    $cj_tempz=curl_exec($ch);
    if($ist!="") $cj_tempz=curl_getinfo($ch);
    curl_close($ch);
    return $cj_tempz;
}
function f_ecr($id,$t){
    $key="A9B3D7F4G2H1J6K8";
    $bmc=substr(strtoupper(md5($id.strtoupper(dechex($t)))),8,16);
    $enc=base64_encode(openssl_encrypt($bmc,"aes-128-ecb",$key,OPENSSL_RAW_DATA));
    return $enc;
}
function f_dcr($str){
    $key="A9B3D7F4G2H1J6K8";
    $str=base64_decode($str);
    $dec=openssl_decrypt($str,"aes-128-ecb",$key,OPENSSL_RAW_DATA);
    return $dec;
}
function f_hurl($id,$pt){
    if($pt=="") die("404");
    $time=time();
    $hdr=["sign:".f_ecr($id,$time),"X-FORWARDED-FOR:".$_SERVER['REMOTE_ADDR']];
    $pzinfo=json_decode(f_curl("http://cosepg.uni.jsa.bcs.ottcn.com:8084/cms-cdn-exchange//v5/media/encrypt?contentId=".$id."&license=".$pt."&timestamp=".$time,$hdr,"","",0))->result;
    if($pzinfo=="") die("404");
    $pdata=["ContentID"=>"{$id}"];
    $auth=json_decode(f_curl("http://223.105.251.51:33200/EPG/Ott/jsp/Auth.jsp",$hdr,json_encode($pdata),"",0))->AuthCode;
    if($auth==""){
        die("404");
    }elseif($auth=="accountinfo="){
        f_hurl($id);
    }else{
        $purl=f_curl("http://183.207.249.71/".$pt."/live1/".$id."/".$id,"","","",1)["redirect_url"];
        $purl=str_replace("http://","http://tptvh.mobaibox.com/hwcdnbacksourceflag_",explode("?",$purl)[0])."?".$auth."&OTTUserToken=DaBenDan&UserName=DaBenDan&pzinfo=".f_dcr($pzinfo);
        return $purl;
    }
}
$id=str_replace(".m3u8","",$_GET["id"]);
if($id=="") die("404");
$purl=f_hurl($id,$_GET["p"]);
if($purl=="") die("404");
header('location:'.$purl);
die();
?>
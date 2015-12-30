学习cocos2dx，项目发布的时候，总是需要加密的，不然，别人通过解包的操作，你的资源和代码，都会看到你的源代码和资源。
因为以前没有接触这个加密，所以决定丰富一下，研究下加密的方式方法，，还有记录一下，这个过程中跳过的坑
经过各方查资料，中午知道cocos2dx的加密方式是用的XXTEA，第三方的库
在cocos引擎的 cocos2d-x-3.9/tools/cocos2d-console/bin 的这个目录下执行cocos的命令行程序，输入./cocos --help 
即可看到compile 以及luacompile
 cocos luacompile [-h] [-v] [-s SRC_DIR_ARR] [-d DST_DIR] [-e]
                        [-k ENCRYPTKEY] [-b ENCRYPTSIGN] [--disable-compile]
然后执行 ./cocos luacompile -s /Users/playcrab/Documents/心学习/studyCocos2d/src -d /Users/playcrab/Documents/心学习/studyCocos2d/src-s -e -k '2dxLua' -b 'XXTEA' 
参数解析：-s 需要加密的文件的路径
		-d 加密后的文件路径以及名字
		-e Whether or not to encrypt lua files 是否加密lua的文件 暂时不需要这个参数
		-k 加密的钥匙
		-b 加密方法
如果加上[--disable-compile] 这个参数，程序加载的时候，会找不到文件，程序直接黑屏
cocos luacompile -s src -d encrypt/src -k key_2015 -b 2015XXTEA --encrypt --disable-compile 
而且有这个参数跟没有这个参数，加密之后的文件是不同的
这个参数的意思是进行字码编译，通过luajit编译。
问题来了，luajit在arm64平台下的luajit的bytecode与早前的bytecode有区别无法直接在mac下编译后在arm64平台使用。它使用了最新的lj_gc64与lj_fr2。所以直接在macos下编译的lua代码不能在ios上运行。需要上传源代码在ios下编译
所以经过编译的代码，并不能在64位mac下进行识别，所以导致黑屏
而luajit是lua的解释器，会单独开一篇，来研究luajit
经过加密的文件，要想在程序中使用，需要在appdelegate文件里加一行代码：
auto engine = LuaEngine::getInstance();
ScriptEngineManager::getInstance()->setScriptEngine(engine);
lua_State* L = engine->getLuaStack()->getLuaState();
lua_module_register(L);

register_all_packages();
LuaStack* stack = engine->getLuaStack();
--最重要的一行
stack->setXXTEAKeyAndSign("2dxLua", strlen("2dxLua"), "XXTEA", strlen("XXTEA"));


--因为luajit的原因，在mac下，只加密，不进行字节编译

抛开项目说加密的两种解决方法：
1、轻量级：apk打包前，用工具把所有的lua文件加密，具体是将lua文件读到内存，然后使用zip等压缩加密库进行压缩加密，然后将压缩加密之后的数据保存为和源文件同名的文件。打包之后运行lua文件的时候
，则先读出lua数据，然后进行解密，将解密的数据流传给lua虚拟机
2、重量级的解决方案：此方案是上一种方案的扩展，实现一个游戏文件包，打包前将资源和脚本都使用工具打包到一个文件，可以在打包的时候加密压缩，也可以不加密压缩。然后在运行的时候直接从包里读出相应
文件的数据，然后解密解压缩，然后提供给游戏引擎使用。
int write_file_content(const char* folder){
　　//获得文件数据，并压缩文件
　　FILE* fpin = fopen(folder, "wb+");
　　if (fpin == NULL)
　　{
　　printf("无法读取文件: %s\n", folder);
　　return 0;
　　}
　　//得到文件大小
　　fseek(fpin, 0, SEEK_END);
　　unsigned int size = ftell(fpin);
　　//读出文件内容
　　fseek(fpin, 0, SEEK_SET);
　　void* con = malloc(size);
　　int r = fread(con, size, 1, fpin);
　　//进行加密操作
　　unsigned long zip_con_size = size * 2;
　　void* zip_con = malloc(zip_con_size);
　　if (Z_OK != compress((Bytef*)zip_con, &zip_con_size, (Bytef*)con, size)){
　　printf("压缩 %s 时发生错误\n",folder);
　　}
　　printf("%s 压缩前大小：%ld 压缩后大小：%ld\n", folder, size, zip_con_size);//写文件内容
　　fseek(fpin, 0, SEEK_SET);
　　int len = fwrite(zip_con, zip_con_size, 1, fpin);//释放资源
　　fclose(fpin);
　　free(zip_con);
　　free(con);
　　return 0;
　　}
　　复制代码
　　然后是解密操作，代码如下：
　　void* read_file_content(const char* folder, int& bufflen){
　　FILE* file = fopen(folder, "wb+");
　　if (file)
　　{
　　{
　　printf("无法读取文件: %s\n", folder);
　　return 0;
　　}
　　//获取文件大小
　　fseek(file, 0, SEEK_END);
　　unsigned int size = ftell(file);
　　//读出文件内容
　　void* con = malloc(size);
　　fseek(file, 0, SEEK_SET);
　　int len = fread(con, size, 1, file);
　　//解压缩操作
　　unsigned long zip_size = size * 4;
　　void* zip_con = malloc(zip_size);
　　int code = uncompress((Bytef*)zip_con, &zip_size, (Bytef*)con, size);if (Z_OK != code)
　　{
　　printf("解压 %s 时发生错误 :%d\n", folder, code);return 0;
　　}
　　//释放资源
　　fclose(file);
　　free(con);
　　//zip_con由外部释放
　　bufflen = zip_size;
　　return zip_con；
}


























































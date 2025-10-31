#include "slang.h"
#include <cassert>
#include <iostream>
#include <string.h>
#include <string>

extern "C" char slang_args_buffer[1024] = {0};
extern "C" uint32_t slang_args_buffer_end = 0;

namespace test {

static void appendArgImpl(const void *data, uint32_t len) {
  assert(slang_args_buffer_end + len <= sizeof(slang_args_buffer) &&
         "Slang argument buffer overflow");
  memcpy(slang_args_buffer + slang_args_buffer_end, data, len);
  slang_args_buffer_end += len;
}

template <typename T> static void appendArg(const T &value) {
  appendArgImpl(&value, sizeof(T));
}

static void beginArgs(std::string_view func_name) {
  memset(slang_args_buffer, 0, slang_args_buffer_end);
  slang_args_buffer_end = 0;
  appendArgImpl(func_name.data(), func_name.size());
}

#define OVERRIDE(name, foo, bar)                                               \
  struct name : foo {                                                          \
    bar                                                                        \
  }

#define OVERRIDE_IUNKNOWN(class_name)                                          \
  SLANG_NO_THROW SlangResult SLANG_MCALL queryInterface(                       \
      SlangUUID const &uuid, void **outObject) override {                      \
    beginArgs(class_name ".queryInterface");                                   \
    appendArg(this);                                                           \
    appendArg(&uuid);                                                          \
    appendArg(outObject);                                                      \
    return 0;                                                                  \
  }                                                                            \
  SLANG_NO_THROW uint32_t SLANG_MCALL addRef() override {                      \
    beginArgs(class_name ".addRef");                                           \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
  SLANG_NO_THROW uint32_t SLANG_MCALL release() override {                     \
    beginArgs(class_name ".release");                                          \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_ICASTABLE(class_name)                                         \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW void *SLANG_MCALL castAs(const SlangUUID &guid) override {    \
    beginArgs(class_name ".castAs");                                           \
    appendArg(this);                                                           \
    appendArg(&guid);                                                          \
    return 0;                                                                  \
  }

#define OVERRIDE_ICLONABLE(class_name)                                         \
  OVERRIDE_ICASTABLE(class_name)                                               \
  SLANG_NO_THROW void *SLANG_MCALL clone(const SlangUUID &guid) override {     \
    beginArgs(class_name ".clone");                                            \
    appendArg(this);                                                           \
    appendArg(&guid);                                                          \
    return 0;                                                                  \
  }

#define OVERRIDE_IBLOB(class_name)                                             \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW void const *SLANG_MCALL getBufferPointer() override {         \
    beginArgs(class_name ".getBufferPointer");                                 \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
  SLANG_NO_THROW size_t SLANG_MCALL getBufferSize() override {                 \
    beginArgs(class_name ".getBufferSize");                                    \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_IFILE_SYSTEM(class_name)                                      \
  OVERRIDE_ICASTABLE(class_name)                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL loadFile(                             \
      char const *path, ISlangBlob **outBlob) override {                       \
    beginArgs(class_name ".loadFile");                                         \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(outBlob);                                                        \
    return 0;                                                                  \
  }

#define OVERRIDE_ISHARED_LIBRARY(class_name)                                   \
  OVERRIDE_ICASTABLE(class_name)                                               \
  SLANG_NO_THROW void *SLANG_MCALL findSymbolAddressByName(char const *name)   \
      override {                                                               \
    beginArgs(class_name ".findSymbolAddressByName");                          \
    appendArg(this);                                                           \
    appendArg(name);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_ISHARED_LIBRARY_LOADER(class_name)                            \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW SlangResult SLANG_MCALL loadSharedLibrary(                    \
      const char *path, ISlangSharedLibrary **sharedLibraryOut) override {     \
    beginArgs(class_name ".loadSharedLibrary");                                \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(sharedLibraryOut);                                               \
    return 0;                                                                  \
  }

#define OVERRIDE_IFILE_SYSTEM_EXT(class_name)                                  \
  OVERRIDE_IFILE_SYSTEM(class_name)                                            \
  SLANG_NO_THROW SlangResult SLANG_MCALL getFileUniqueIdentity(                \
      const char *path, ISlangBlob **outUniqueIdentity) override {             \
    beginArgs(class_name ".getFileUniqueIdentity");                            \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(outUniqueIdentity);                                              \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL calcCombinedPath(                     \
      SlangPathType fromPathType, const char *fromPath, const char *path,      \
      ISlangBlob **pathOut) override {                                         \
    beginArgs(class_name ".calcCombinedPath");                                 \
    appendArg(this);                                                           \
    appendArg(fromPathType);                                                   \
    appendArg(fromPath);                                                       \
    appendArg(path);                                                           \
    appendArg(pathOut);                                                        \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getPathType(                          \
      const char *path, SlangPathType *pathTypeOut) override {                 \
    beginArgs(class_name ".getPathType");                                      \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(pathTypeOut);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getPath(                              \
      PathKind kind, const char *path, ISlangBlob **outPath) override {        \
    beginArgs(class_name ".getPath");                                          \
    appendArg(this);                                                           \
    appendArg(kind);                                                           \
    appendArg(path);                                                           \
    appendArg(outPath);                                                        \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL clearCache() override {                      \
    beginArgs(class_name ".clearCache");                                       \
    appendArg(this);                                                           \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL enumeratePathContents(                \
      const char *path, FileSystemContentsCallBack callback, void *userData)   \
      override {                                                               \
    beginArgs(class_name ".enumeratePathContents");                            \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(callback);                                                       \
    appendArg(userData);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW OSPathKind SLANG_MCALL getOSPathKind() override {             \
    beginArgs(class_name ".getOSPathKind");                                    \
    appendArg(this);                                                           \
    return OSPathKind::None;                                                   \
  }

#define OVERRIDE_IMUTABLE_FILE_SYSTEM(class_name)                              \
  OVERRIDE_IFILE_SYSTEM_EXT(class_name)                                        \
  SLANG_NO_THROW SlangResult SLANG_MCALL saveFile(                             \
      const char *path, const void *data, size_t size) override {              \
    beginArgs(class_name ".saveFile");                                         \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(data);                                                           \
    appendArg(size);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL saveFileBlob(                         \
      const char *path, ISlangBlob *dataBlob) override {                       \
    beginArgs(class_name ".saveFileBlob");                                     \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    appendArg(dataBlob);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL remove(const char *path) override {   \
    beginArgs(class_name ".remove");                                           \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL createDirectory(const char *path)     \
      override {                                                               \
    beginArgs(class_name ".createDirectory");                                  \
    appendArg(this);                                                           \
    appendArg(path);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_IWRITER(class_name)                                           \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW char *SLANG_MCALL beginAppendBuffer(size_t maxNumChars)       \
      override {                                                               \
    beginArgs(class_name ".beginAppendBuffer");                                \
    appendArg(this);                                                           \
    appendArg(maxNumChars);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL endAppendBuffer(                      \
      char *buffer, size_t numChars) override {                                \
    beginArgs(class_name ".endAppendBuffer");                                  \
    appendArg(this);                                                           \
    appendArg(buffer);                                                         \
    appendArg(numChars);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL write(const char *chars,              \
                                               size_t numChars) override {     \
    beginArgs(class_name ".write");                                            \
    appendArg(this);                                                           \
    appendArg(chars);                                                          \
    appendArg(numChars);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL flush() override {                           \
    beginArgs(class_name ".flush");                                            \
    appendArg(this);                                                           \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangBool SLANG_MCALL isConsole() override {                  \
    beginArgs(class_name ".isConsole");                                        \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL setMode(SlangWriterMode mode)         \
      override {                                                               \
    beginArgs(class_name ".setMode");                                          \
    appendArg(this);                                                           \
    appendArg(mode);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_IPROFILER(class_name)                                         \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW size_t SLANG_MCALL getEntryCount() override {                 \
    beginArgs(class_name ".getEntryCount");                                    \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW const char *SLANG_MCALL getEntryName(uint32_t index)          \
      override {                                                               \
    beginArgs(class_name ".getEntryName");                                     \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW long SLANG_MCALL getEntryTimeMS(uint32_t index) override {    \
    beginArgs(class_name ".getEntryTimeMS");                                   \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW uint32_t SLANG_MCALL getEntryInvocationTimes(uint32_t index)  \
      override {                                                               \
    beginArgs(class_name ".getEntryInvocationTimes");                          \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    return 0;                                                                  \
  }

#define OVERRIDE_IGLOBAL_SESSION(class_name)                                   \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW SlangResult SLANG_MCALL createSession(                        \
      slang::SessionDesc const &desc, slang::ISession **outSession) override { \
    beginArgs(class_name ".createSession");                                    \
    appendArg(this);                                                           \
    appendArg(&desc);                                                          \
    appendArg(outSession);                                                     \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangProfileID SLANG_MCALL findProfile(char const *name)      \
      override {                                                               \
    beginArgs(class_name ".findProfile");                                      \
    appendArg(this);                                                           \
    appendArg(name);                                                           \
    return SlangProfileID::SLANG_PROFILE_UNKNOWN;                              \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL setDownstreamCompilerPath(                   \
      SlangPassThrough passThrough, char const *path) override {               \
    beginArgs(class_name ".setDownstreamCompilerPath");                        \
    appendArg(this);                                                           \
    appendArg(passThrough);                                                    \
    appendArg(path);                                                           \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL setDownstreamCompilerPrelude(                \
      SlangPassThrough passThrough, const char *preludeText) override {        \
    beginArgs(class_name ".setDownstreamCompilerPrelude");                     \
    appendArg(this);                                                           \
    appendArg(passThrough);                                                    \
    appendArg(preludeText);                                                    \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL getDownstreamCompilerPrelude(                \
      SlangPassThrough passThrough, ISlangBlob **outPrelude) override {        \
    beginArgs(class_name ".getDownstreamCompilerPrelude");                     \
    appendArg(this);                                                           \
    appendArg(passThrough);                                                    \
    appendArg(outPrelude);                                                     \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW const char *SLANG_MCALL getBuildTagString() override {        \
    beginArgs(class_name ".getBuildTagString");                                \
    appendArg(this);                                                           \
    return "unknown";                                                          \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL setDefaultDownstreamCompiler(         \
      SlangSourceLanguage sourceLanguage, SlangPassThrough defaultCompiler)    \
      override {                                                               \
    beginArgs(class_name ".setDefaultDownstreamCompiler");                     \
    appendArg(this);                                                           \
    appendArg(sourceLanguage);                                                 \
    appendArg(defaultCompiler);                                                \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SlangPassThrough SLANG_MCALL getDefaultDownstreamCompiler(                   \
      SlangSourceLanguage sourceLanguage) override {                           \
    beginArgs(class_name ".getDefaultDownstreamCompiler");                     \
    appendArg(this);                                                           \
    appendArg(sourceLanguage);                                                 \
    return SlangPassThrough::SLANG_PASS_THROUGH_NONE;                          \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL setLanguagePrelude(                          \
      SlangSourceLanguage sourceLanguage, const char *preludeText) override {  \
    beginArgs(class_name ".setLanguagePrelude");                               \
    appendArg(this);                                                           \
    appendArg(sourceLanguage);                                                 \
    appendArg(preludeText);                                                    \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL getLanguagePrelude(                          \
      SlangSourceLanguage sourceLanguage, ISlangBlob **outPrelude) override {  \
    beginArgs(class_name ".getLanguagePrelude");                               \
    appendArg(this);                                                           \
    appendArg(sourceLanguage);                                                 \
    appendArg(outPrelude);                                                     \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL createCompileRequest(                 \
      slang::ICompileRequest **outCompileRequest) override {                   \
    beginArgs(class_name ".createCompileRequest");                             \
    appendArg(this);                                                           \
    appendArg(outCompileRequest);                                              \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL addBuiltins(                                 \
      char const *sourcePath, char const *sourceString) override {             \
    beginArgs(class_name ".addBuiltins");                                      \
    appendArg(this);                                                           \
    appendArg(sourcePath);                                                     \
    appendArg(sourceString);                                                   \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL setSharedLibraryLoader(                      \
      ISlangSharedLibraryLoader *loader) override {                            \
    beginArgs(class_name ".setSharedLibraryLoader");                           \
    appendArg(this);                                                           \
    appendArg(loader);                                                         \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW ISlangSharedLibraryLoader *SLANG_MCALL                        \
  getSharedLibraryLoader() override {                                          \
    beginArgs(class_name ".getSharedLibraryLoader");                           \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL checkCompileTargetSupport(            \
      SlangCompileTarget target) override {                                    \
    beginArgs(class_name ".checkCompileTargetSupport");                        \
    appendArg(this);                                                           \
    appendArg(target);                                                         \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL checkPassThroughSupport(              \
      SlangPassThrough passThrough) override {                                 \
    beginArgs(class_name ".checkPassThroughSupport");                          \
    appendArg(this);                                                           \
    appendArg(passThrough);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL compileCoreModule(                    \
      slang::CompileCoreModuleFlags flags) override {                          \
    beginArgs(class_name ".compileCoreModule");                                \
    appendArg(this);                                                           \
    appendArg(flags);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL loadCoreModule(                       \
      const void *coreModule, size_t coreModuleSizeInBytes) override {         \
    beginArgs(class_name ".loadCoreModule");                                   \
    appendArg(this);                                                           \
    appendArg(coreModule);                                                     \
    appendArg(coreModuleSizeInBytes);                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL saveCoreModule(                       \
      SlangArchiveType archiveType, ISlangBlob **outBlob) override {           \
    beginArgs(class_name ".saveCoreModule");                                   \
    appendArg(this);                                                           \
    appendArg(archiveType);                                                    \
    appendArg(outBlob);                                                        \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangCapabilityID SLANG_MCALL findCapability(                 \
      char const *name) override {                                             \
    beginArgs(class_name ".findCapability");                                   \
    appendArg(this);                                                           \
    appendArg(name);                                                           \
    return SlangCapabilityID::SLANG_CAPABILITY_UNKNOWN;                        \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL setDownstreamCompilerForTransition(          \
      SlangCompileTarget source, SlangCompileTarget target,                    \
      SlangPassThrough compiler) override {                                    \
    beginArgs(class_name ".setDownstreamCompilerForTransition");               \
    appendArg(this);                                                           \
    appendArg(source);                                                         \
    appendArg(target);                                                         \
    appendArg(compiler);                                                       \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangPassThrough SLANG_MCALL                                  \
  getDownstreamCompilerForTransition(SlangCompileTarget source,                \
                                     SlangCompileTarget target) override {     \
    beginArgs(class_name ".getDownstreamCompilerForTransition");               \
    appendArg(this);                                                           \
    appendArg(source);                                                         \
    appendArg(target);                                                         \
    return SlangPassThrough::SLANG_PASS_THROUGH_NONE;                          \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL getCompilerElapsedTime(                      \
      double *outTotalTime, double *outDownstreamTime) override {              \
    beginArgs(class_name ".getCompilerElapsedTime");                           \
    appendArg(this);                                                           \
    appendArg(outTotalTime);                                                   \
    appendArg(outDownstreamTime);                                              \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL setSPIRVCoreGrammar(                  \
      char const *jsonPath) override {                                         \
    beginArgs(class_name ".setSPIRVCoreGrammar");                              \
    appendArg(this);                                                           \
    appendArg(jsonPath);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL parseCommandLineArguments(            \
      int argc, const char *const *argv, slang::SessionDesc *outSessionDesc,   \
      ISlangUnknown **outAuxAllocation) override {                             \
    beginArgs(class_name ".parseCommandLineArguments");                        \
    appendArg(this);                                                           \
    appendArg(argc);                                                           \
    appendArg(argv);                                                           \
    appendArg(outSessionDesc);                                                 \
    appendArg(outAuxAllocation);                                               \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getSessionDescDigest(                 \
      slang::SessionDesc *sessionDesc, ISlangBlob **outBlob) override {        \
    beginArgs(class_name ".getSessionDescDigest");                             \
    appendArg(this);                                                           \
    appendArg(sessionDesc);                                                    \
    appendArg(outBlob);                                                        \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL compileBuiltinModule(                 \
      slang::BuiltinModuleName module, slang::CompileCoreModuleFlags flags)    \
      override {                                                               \
    beginArgs(class_name ".compileBuiltinModule");                             \
    appendArg(this);                                                           \
    appendArg(module);                                                         \
    appendArg(flags);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL loadBuiltinModule(                    \
      slang::BuiltinModuleName module, const void *moduleData,                 \
      size_t sizeInBytes) override {                                           \
    beginArgs(class_name ".loadBuiltinModule");                                \
    appendArg(this);                                                           \
    appendArg(module);                                                         \
    appendArg(moduleData);                                                     \
    appendArg(sizeInBytes);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL saveBuiltinModule(                    \
      slang::BuiltinModuleName module, SlangArchiveType archiveType,           \
      ISlangBlob **outBlob) override {                                         \
    beginArgs(class_name ".saveBuiltinModule");                                \
    appendArg(this);                                                           \
    appendArg(module);                                                         \
    appendArg(archiveType);                                                    \
    appendArg(outBlob);                                                        \
    return 0;                                                                  \
  }

#define OVERRIDE_ISESSION(class_name)                                          \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW slang::IGlobalSession *SLANG_MCALL getGlobalSession()         \
      override {                                                               \
    beginArgs(class_name ".getGlobalSession");                                 \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::IModule *SLANG_MCALL loadModule(                       \
      const char *moduleName, ISlangBlob **outDiagnostics = nullptr)           \
      override {                                                               \
    beginArgs(class_name ".loadModule");                                       \
    appendArg(this);                                                           \
    appendArg(moduleName);                                                     \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::IModule *SLANG_MCALL loadModuleFromSource(             \
      const char *moduleName, const char *path, ISlangBlob *source,            \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".loadModuleFromSource");                             \
    appendArg(this);                                                           \
    appendArg(moduleName);                                                     \
    appendArg(path);                                                           \
    appendArg(source);                                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL createCompositeComponentType(         \
      slang::IComponentType *const *componentTypes,                            \
      SlangInt componentTypeCount,                                             \
      slang::IComponentType **outCompositeComponentType,                       \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".createCompositeComponentType");                     \
    appendArg(this);                                                           \
    appendArg(componentTypes);                                                 \
    appendArg(componentTypeCount);                                             \
    appendArg(outCompositeComponentType);                                      \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::TypeReflection *SLANG_MCALL specializeType(            \
      slang::TypeReflection *type,                                             \
      slang::SpecializationArg const *specializationArgs,                      \
      SlangInt specializationArgCount, ISlangBlob **outDiagnostics = nullptr)  \
      override {                                                               \
    beginArgs(class_name ".specializeType");                                   \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(specializationArgs);                                             \
    appendArg(specializationArgCount);                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::TypeLayoutReflection *SLANG_MCALL getTypeLayout(       \
      slang::TypeReflection *type, SlangInt targetIndex = 0,                   \
      slang::LayoutRules rules = slang::LayoutRules::Default,                  \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getTypeLayout");                                    \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(targetIndex);                                                    \
    appendArg(rules);                                                          \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::TypeReflection *SLANG_MCALL getContainerType(          \
      slang::TypeReflection *elementType, slang::ContainerType containerType,  \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getContainerType");                                 \
    appendArg(this);                                                           \
    appendArg(elementType);                                                    \
    appendArg(containerType);                                                  \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::TypeReflection *SLANG_MCALL getDynamicType()           \
      override {                                                               \
    beginArgs(class_name ".getDynamicType");                                   \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getTypeRTTIMangledName(               \
      slang::TypeReflection *type, ISlangBlob **outNameBlob) override {        \
    beginArgs(class_name ".getTypeRTTIMangledName");                           \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(outNameBlob);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getTypeConformanceWitnessMangledName( \
      slang::TypeReflection *type, slang::TypeReflection *interfaceType,       \
      ISlangBlob **outNameBlob) override {                                     \
    beginArgs(class_name ".getTypeConformanceWitnessMangledName");             \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(interfaceType);                                                  \
    appendArg(outNameBlob);                                                    \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL                                       \
  getTypeConformanceWitnessSequentialID(slang::TypeReflection *type,           \
                                        slang::TypeReflection *interfaceType,  \
                                        uint32_t *outId) override {            \
    beginArgs(class_name ".getTypeConformanceWitnessSequentialID");            \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(interfaceType);                                                  \
    appendArg(outId);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL createCompileRequest(                 \
      SlangCompileRequest **outCompileRequest) override {                      \
    beginArgs(class_name ".createCompileRequest");                             \
    appendArg(this);                                                           \
    appendArg(outCompileRequest);                                              \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL createTypeConformanceComponentType(   \
      slang::TypeReflection *type, slang::TypeReflection *interfaceType,       \
      slang::ITypeConformance **outConformance,                                \
      SlangInt conformanceIdOverride, ISlangBlob **outDiagnostics) override {  \
    beginArgs(class_name ".createTypeConformanceComponentType");               \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(interfaceType);                                                  \
    appendArg(outConformance);                                                 \
    appendArg(conformanceIdOverride);                                          \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::IModule *SLANG_MCALL loadModuleFromIRBlob(             \
      const char *moduleName, const char *path, ISlangBlob *source,            \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".loadModuleFromIRBlob");                             \
    appendArg(this);                                                           \
    appendArg(moduleName);                                                     \
    appendArg(path);                                                           \
    appendArg(source);                                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangInt SLANG_MCALL getLoadedModuleCount() override {        \
    beginArgs(class_name ".getLoadedModuleCount");                             \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::IModule *SLANG_MCALL getLoadedModule(SlangInt index)   \
      override {                                                               \
    beginArgs(class_name ".getLoadedModule");                                  \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW bool SLANG_MCALL isBinaryModuleUpToDate(                      \
      const char *modulePath, ISlangBlob *binaryModuleBlob) override {         \
    beginArgs(class_name ".isBinaryModuleUpToDate");                           \
    appendArg(this);                                                           \
    appendArg(modulePath);                                                     \
    appendArg(binaryModuleBlob);                                               \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::IModule *SLANG_MCALL loadModuleFromSourceString(       \
      const char *moduleName, const char *path, const char *string,            \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".loadModuleFromSourceString");                       \
    appendArg(this);                                                           \
    appendArg(moduleName);                                                     \
    appendArg(path);                                                           \
    appendArg(string);                                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getDynamicObjectRTTIBytes(            \
      slang::TypeReflection *type, slang::TypeReflection *interfaceType,       \
      uint32_t *outRTTIDataBuffer, uint32_t bufferSizeInBytes) override {      \
    beginArgs(class_name ".getDynamicObjectRTTIBytes");                        \
    appendArg(this);                                                           \
    appendArg(type);                                                           \
    appendArg(interfaceType);                                                  \
    appendArg(outRTTIDataBuffer);                                              \
    appendArg(bufferSizeInBytes);                                              \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL loadModuleInfoFromIRBlob(             \
      ISlangBlob *source, SlangInt &outModuleVersion,                          \
      const char *&outModuleCompilerVersion, const char *&outModuleName)       \
      override {                                                               \
    beginArgs(class_name ".loadModuleInfoFromIRBlob");                         \
    appendArg(this);                                                           \
    appendArg(source);                                                         \
    appendArg(&outModuleVersion);                                              \
    appendArg(&outModuleCompilerVersion);                                      \
    appendArg(&outModuleName);                                                 \
    return 0;                                                                  \
  }

#define OVERRIDE_IMETADATA(class_name)                                         \
  OVERRIDE_ICASTABLE(class_name)                                               \
  SlangResult isParameterLocationUsed(                                         \
      SlangParameterCategory category, SlangUInt spaceIndex,                   \
      SlangUInt registerIndex, bool &outUsed) override {                       \
    beginArgs(class_name ".isParameterLocationUsed");                          \
    appendArg(this);                                                           \
    appendArg(category);                                                       \
    appendArg(spaceIndex);                                                     \
    appendArg(registerIndex);                                                  \
    appendArg(&outUsed);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  const char *SLANG_MCALL getDebugBuildIdentifier() override {                 \
    beginArgs(class_name ".getDebugBuildIdentifier");                          \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_ICOMPILE_RESULT(class_name)                                   \
  OVERRIDE_ICASTABLE(class_name)                                               \
  uint32_t SLANG_MCALL getItemCount() override {                               \
    beginArgs(class_name ".getItemCount");                                     \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SlangResult SLANG_MCALL getItemData(uint32_t index, ISlangBlob **outblob)    \
      override {                                                               \
    beginArgs(class_name ".getItemData");                                      \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    appendArg(outblob);                                                        \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SlangResult SLANG_MCALL getMetadata(slang::IMetadata **outMetadata)          \
      override {                                                               \
    beginArgs(class_name ".getMetadata");                                      \
    appendArg(this);                                                           \
    appendArg(outMetadata);                                                    \
    return 0;                                                                  \
  }

#define OVERRIDE_ICOMPONENT_TYPE(class_name)                                   \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW slang::ISession *SLANG_MCALL getSession() override {          \
    beginArgs(class_name ".getSession");                                       \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::ProgramLayout *SLANG_MCALL getLayout(                  \
      SlangInt targetIndex = 0, ISlangBlob **outDiagnostics = nullptr)         \
      override {                                                               \
    beginArgs(class_name ".getLayout");                                        \
    appendArg(this);                                                           \
    appendArg(targetIndex);                                                    \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangInt SLANG_MCALL getSpecializationParamCount() override { \
    beginArgs(class_name ".getSpecializationParamCount");                      \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getEntryPointCode(                    \
      SlangInt entryPointIndex, SlangInt targetIndex, ISlangBlob **outCode,    \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getEntryPointCode");                                \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outCode);                                                        \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getResultAsFileSystem(                \
      SlangInt entryPointIndex, SlangInt targetIndex,                          \
      ISlangMutableFileSystem **outFileSystem) override {                      \
    beginArgs(class_name ".getResultAsFileSystem");                            \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outFileSystem);                                                  \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW void SLANG_MCALL getEntryPointHash(                           \
      SlangInt entryPointIndex, SlangInt targetIndex, ISlangBlob **outHash)    \
      override {                                                               \
    beginArgs(class_name ".getEntryPointHash");                                \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outHash);                                                        \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL specialize(                           \
      slang::SpecializationArg const *specializationArgs,                      \
      SlangInt specializationArgCount,                                         \
      slang::IComponentType **outSpecializedComponentType,                     \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".specialize");                                       \
    appendArg(this);                                                           \
    appendArg(specializationArgs);                                             \
    appendArg(specializationArgCount);                                         \
    appendArg(outSpecializedComponentType);                                    \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL link(                                 \
      slang::IComponentType **outLinkedComponentType,                          \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".link");                                             \
    appendArg(this);                                                           \
    appendArg(outLinkedComponentType);                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getEntryPointHostCallable(            \
      int entryPointIndex, int targetIndex,                                    \
      ISlangSharedLibrary **outSharedLibrary, ISlangBlob **outDiagnostics = 0) \
      override {                                                               \
    beginArgs(class_name ".getEntryPointHostCallable");                        \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outSharedLibrary);                                               \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL renameEntryPoint(                     \
      const char *newName, slang::IComponentType **outEntryPoint) override {   \
    beginArgs(class_name ".renameEntryPoint");                                 \
    appendArg(this);                                                           \
    appendArg(newName);                                                        \
    appendArg(outEntryPoint);                                                  \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL linkWithOptions(                      \
      slang::IComponentType **outLinkedComponentType,                          \
      uint32_t compilerOptionEntryCount,                                       \
      slang::CompilerOptionEntry *compilerOptionEntries,                       \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".linkWithOptions");                                  \
    appendArg(this);                                                           \
    appendArg(outLinkedComponentType);                                         \
    appendArg(compilerOptionEntryCount);                                       \
    appendArg(compilerOptionEntries);                                          \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getTargetCode(                        \
      SlangInt targetIndex, ISlangBlob **outCode,                              \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getTargetCode");                                    \
    appendArg(this);                                                           \
    appendArg(targetIndex);                                                    \
    appendArg(outCode);                                                        \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getTargetMetadata(                    \
      SlangInt targetIndex, slang::IMetadata **outMetadata,                    \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getTargetMetadata");                                \
    appendArg(this);                                                           \
    appendArg(targetIndex);                                                    \
    appendArg(outMetadata);                                                    \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getEntryPointMetadata(                \
      SlangInt entryPointIndex, SlangInt targetIndex,                          \
      slang::IMetadata **outMetadata, ISlangBlob **outDiagnostics = nullptr)   \
      override {                                                               \
    beginArgs(class_name ".getEntryPointMetadata");                            \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outMetadata);                                                    \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }

#define OVERRIDE_IENTRY_POINT(class_name)                                      \
  OVERRIDE_ICOMPONENT_TYPE(class_name)                                         \
  SLANG_NO_THROW slang::FunctionReflection *SLANG_MCALL                        \
  getFunctionReflection() override {                                           \
    beginArgs(class_name ".getFunctionReflection");                            \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }

#define OVERRIDE_ICOMPONENT_TYPE2(class_name)                                  \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW SlangResult SLANG_MCALL getTargetCompileResult(               \
      SlangInt targetIndex, slang::ICompileResult **outCompileResult,          \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getTargetCompileResult");                           \
    appendArg(this);                                                           \
    appendArg(targetIndex);                                                    \
    appendArg(outCompileResult);                                               \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getEntryPointCompileResult(           \
      SlangInt entryPointIndex, SlangInt targetIndex,                          \
      slang::ICompileResult **outCompileResult,                                \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getEntryPointCompileResult");                       \
    appendArg(this);                                                           \
    appendArg(entryPointIndex);                                                \
    appendArg(targetIndex);                                                    \
    appendArg(outCompileResult);                                               \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }

#define OVERRIDE_IMODULE(class_name)                                           \
  OVERRIDE_ICOMPONENT_TYPE(class_name)                                         \
  SLANG_NO_THROW SlangResult SLANG_MCALL findEntryPointByName(                 \
      char const *name, slang::IEntryPoint **outEntryPoint) override {         \
    beginArgs(class_name ".findEntryPointByName");                             \
    appendArg(this);                                                           \
    appendArg(name);                                                           \
    appendArg(outEntryPoint);                                                  \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangInt32 SLANG_MCALL getDefinedEntryPointCount() override { \
    beginArgs(class_name ".getDefinedEntryPointCount");                        \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getDefinedEntryPoint(                 \
      SlangInt32 index, slang::IEntryPoint **outEntryPoint) override {         \
    beginArgs(class_name ".getDefinedEntryPoint");                             \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    appendArg(outEntryPoint);                                                  \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL serialize(                            \
      ISlangBlob **outSerializedBlob) override {                               \
    beginArgs(class_name ".serialize");                                        \
    appendArg(this);                                                           \
    appendArg(outSerializedBlob);                                              \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL writeToFile(char const *fileName)     \
      override {                                                               \
    beginArgs(class_name ".writeToFile");                                      \
    appendArg(this);                                                           \
    appendArg(fileName);                                                       \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW const char *SLANG_MCALL getName() override {                  \
    beginArgs(class_name ".getName");                                          \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW const char *SLANG_MCALL getFilePath() override {              \
    beginArgs(class_name ".getFilePath");                                      \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW const char *SLANG_MCALL getUniqueIdentity() override {        \
    beginArgs(class_name ".getUniqueIdentity");                                \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL findAndCheckEntryPoint(               \
      char const *name, SlangStage stage, slang::IEntryPoint **outEntryPoint,  \
      ISlangBlob **outDiagnostics) override {                                  \
    beginArgs(class_name ".findAndCheckEntryPoint");                           \
    appendArg(this);                                                           \
    appendArg(name);                                                           \
    appendArg(stage);                                                          \
    appendArg(outEntryPoint);                                                  \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangInt32 SLANG_MCALL getDependencyFileCount() override {    \
    beginArgs(class_name ".getDependencyFileCount");                           \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW char const *SLANG_MCALL getDependencyFilePath(                \
      SlangInt32 index) override {                                             \
    beginArgs(class_name ".getDependencyFilePath");                            \
    appendArg(this);                                                           \
    appendArg(index);                                                          \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW slang::DeclReflection *SLANG_MCALL getModuleReflection()      \
      override {                                                               \
    beginArgs(class_name ".getModuleReflection");                              \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL disassemble(                          \
      ISlangBlob **outDisassembledBlob) override {                             \
    beginArgs(class_name ".disassemble");                                      \
    appendArg(this);                                                           \
    appendArg(outDisassembledBlob);                                            \
    return 0;                                                                  \
  }

#define OVERRIDE_IMODULE_PRECOMPILE_SERVICE_EXPERIMENTAL(class_name)           \
  OVERRIDE_IUNKNOWN(class_name)                                                \
  SLANG_NO_THROW SlangResult SLANG_MCALL precompileForTarget(                  \
      SlangCompileTarget target, ISlangBlob **outDiagnostics) override {       \
    beginArgs(class_name ".precompileForTarget");                              \
    appendArg(this);                                                           \
    appendArg(target);                                                         \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getPrecompiledTargetCode(             \
      SlangCompileTarget target, ISlangBlob **outCode,                         \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getPrecompiledTargetCode");                         \
    appendArg(this);                                                           \
    appendArg(target);                                                         \
    appendArg(outCode);                                                        \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangInt SLANG_MCALL getModuleDependencyCount() override {    \
    beginArgs(class_name ".getModuleDependencyCount");                         \
    appendArg(this);                                                           \
    return 0;                                                                  \
  }                                                                            \
                                                                               \
  SLANG_NO_THROW SlangResult SLANG_MCALL getModuleDependency(                  \
      SlangInt dependencyIndex, slang::IModule **outModule,                    \
      ISlangBlob **outDiagnostics = nullptr) override {                        \
    beginArgs(class_name ".getModuleDependency");                              \
    appendArg(this);                                                           \
    appendArg(dependencyIndex);                                                \
    appendArg(outModule);                                                      \
    appendArg(outDiagnostics);                                                 \
    return 0;                                                                  \
  }

OVERRIDE(IUnknown, ISlangUnknown, OVERRIDE_IUNKNOWN("IUnknown"));
OVERRIDE(ICastable, ISlangCastable, OVERRIDE_ICASTABLE("ICastable"));
OVERRIDE(IClonable, ISlangClonable, OVERRIDE_ICLONABLE("IClonable"));
OVERRIDE(IBlob, ISlangBlob, OVERRIDE_IBLOB("IBlob"));
OVERRIDE(IFileSystem, ISlangFileSystem, OVERRIDE_IFILE_SYSTEM("IFileSystem"));
OVERRIDE(ISharedLibrary, ISlangSharedLibrary,
         OVERRIDE_ISHARED_LIBRARY("ISharedLibrary"));
OVERRIDE(ISharedLibraryLoader, ISlangSharedLibraryLoader,
         OVERRIDE_ISHARED_LIBRARY_LOADER("ISharedLibraryLoader"));
OVERRIDE(IFileSystemExt, ISlangFileSystemExt,
         OVERRIDE_IFILE_SYSTEM_EXT("IFileSystemExt"));
OVERRIDE(IMutableFileSystem, ISlangMutableFileSystem,
         OVERRIDE_IMUTABLE_FILE_SYSTEM("IMutableFileSystem"));
OVERRIDE(IWriter, ISlangWriter, OVERRIDE_IWRITER("IWriter"));
OVERRIDE(IProfiler, ISlangProfiler, OVERRIDE_IPROFILER("IProfiler"));
// OVERRIDE(ICompileRequest, slang::ICompileRequest,
// OVERRIDE_ICOMPILE_REQUEST("ICompileRequest"));
OVERRIDE(IGlobalSession, slang::IGlobalSession,
         OVERRIDE_IGLOBAL_SESSION("IGlobalSession"));
OVERRIDE(ISession, slang::ISession, OVERRIDE_ISESSION("ISession"));
OVERRIDE(IMetadata, slang::IMetadata, OVERRIDE_IMETADATA("IMetadata"));
OVERRIDE(ICompileResult, slang::ICompileResult,
         OVERRIDE_ICOMPILE_RESULT("ICompileResult"));
OVERRIDE(IComponentType, slang::IComponentType,
         OVERRIDE_ICOMPONENT_TYPE("IComponentType"));
OVERRIDE(IEntryPoint, slang::IEntryPoint, OVERRIDE_IENTRY_POINT("IEntryPoint"));
OVERRIDE(IComponentType2, slang::IComponentType2,
         OVERRIDE_ICOMPONENT_TYPE2("IComponentType2"));
OVERRIDE(IModule, slang::IModule, OVERRIDE_IMODULE("IModule"));
OVERRIDE(IModulePrecompileService_Experimental,
         slang::IModulePrecompileService_Experimental,
         OVERRIDE_IMODULE_PRECOMPILE_SERVICE_EXPERIMENTAL(
             "IModulePrecompileService_Experimental"));
}; // namespace test

struct SlangTestInterfaces {
  test::IUnknown IUnknown;
  test::ICastable ICastable;
  test::IClonable IClonable;
  test::IBlob IBlob;
  test::IFileSystem IFileSystem;
  test::ISharedLibrary ISharedLibrary;
  test::ISharedLibraryLoader ISharedLibraryLoader;
  test::IFileSystemExt IFileSystemExt;
  test::IMutableFileSystem IMutableFileSystem;
  test::IWriter IWriter;
  test::IProfiler IProfiler;
  test::IGlobalSession IGlobalSession;
  test::ISession ISession;
  test::IMetadata IMetadata;
  test::ICompileResult ICompileResult;
  test::IComponentType IComponentType;
  test::IEntryPoint IEntryPoint;
  test::IComponentType2 IComponentType2;
  test::IModule IModule;
  test::IModulePrecompileService_Experimental
      IModulePrecompileService_Experimental;
};

extern "C" SlangTestInterfaces slang_test_interfaces{};

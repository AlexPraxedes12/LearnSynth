#pragma once
#include <string>
#include <functional>
#include <memory>

struct LlamaEngineConfig {
  std::string model_path;
  int n_ctx = 2048;
  int n_threads = 4;
  float temperature = 0.2f;
  int max_tokens = 256;
};

class LlamaEngine {
public:
  static std::unique_ptr<LlamaEngine> create(const LlamaEngineConfig& cfg);
  virtual ~LlamaEngine() {}
  virtual bool is_ready() const = 0;
  virtual void cancel() = 0;
  virtual bool generate(const std::string& prompt,
                        std::function<void(const std::string&)> on_token) = 0;
};

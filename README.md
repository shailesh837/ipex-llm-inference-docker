# IPEX-LLM Inference Docker (Custom Setup)

This repository guides you through setting up a custom Docker environment for IPEX-LLM inference using Intel hardware.

## Prerequisites

- Docker installed on your system.
- Git installed on your system.
- Intel GPU Drivers compatible with IPEX-LLM.
  - Recommended: [Intel Compute Runtime 25.13.33276.16](https://github.com/intel/compute-runtime/releases/tag/25.13.33276.16)

## Steps to Setup

1. **Clone the Official IPEX-LLM Repository:**

   ```bash
   git clone https://github.com/intel/ipex-llm.git
   cd ipex-llm/docker/llm/inference-cpp
   ```

2. **Replace Dockerfile:**

   Replace the existing `Dockerfile` in `docker/llm/inference-cpp` with the custom Dockerfile from this repository:

   ```bash
   curl -o Dockerfile https://raw.githubusercontent.com/shailesh837/ipex-llm-inference-docker/main/Dockerfile
   ```

3. **Build the Docker Image:**

   Follow the instructions from the official README inside the `docker/llm/inference-cpp` directory.

   Example Docker build command:

   ```bash
   docker build -t ipex-llm-inference-cpp .
   ```

4. **Test the Docker Image:**

   Run the Docker container and perform inference tests as per the instructions from the official README.

   Example:

   ```bash
   docker run --rm -it ipex-llm-inference-cpp
   ```

## Notes

- Ensure your Intel GPU drivers are correctly installed and compatible with the version of Compute Runtime mentioned above.
- This setup assumes that all other configurations and dependencies remain unchanged from the official `ipex-llm` repository.
- The custom Dockerfile provides optimizations or modifications tailored for specific environments.

## References

- Official IPEX-LLM Repository: [https://github.com/intel/ipex-llm](https://github.com/intel/ipex-llm)
- Custom Dockerfile: [https://github.com/shailesh837/ipex-llm-inference-docker/Dockerfile](https://github.com/shailesh837/ipex-llm-inference-docker/Dockerfile)
- Intel Compute Runtime: [https://github.com/intel/compute-runtime/releases/tag/25.13.33276.16](https://github.com/intel/compute-runtime/releases/tag/25.13.33276.16)

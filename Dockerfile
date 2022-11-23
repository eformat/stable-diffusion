# FIXME this base downloader image is just cause its got git etc setup but its bloated
FROM quay.io/rht-labs/stack-tl500:3.0.16 as download

WORKDIR /projects

COPY clone.sh .

RUN ./clone.sh taming-transformers https://github.com/CompVis/taming-transformers.git 24268930bf1dce879235a7fddd0b2355b84d7ea6 \
  && rm -rf data assets **/*.ipynb

RUN ./clone.sh stable-diffusion https://github.com/CompVis/stable-diffusion.git 69ae4b35e0a0f6ee1af8bb9a5d0016ccb27e36dc \
  && rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

RUN ./clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git c5b4593074ba6214284d6acd5f1719b6c5d739af \
  && rm -rf assets inputs

RUN ./clone.sh BLIP https://github.com/salesforce/BLIP.git 48211a1594f1321b00f14c9f7a5b4813144b2fb9
RUN ./clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 60e5042ca0da89c14d1dd59d73883280f8fce991
RUN ./clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator 2486589f24165c8e3b303f84e9dbbea318df83e8

# fc36 base from here on
FROM quay.io/fedora/fedora:36 as xformers
RUN dnf -y install aria2
RUN aria2c --dir / --out wheel.whl 'https://github.com/AbdBarho/stable-diffusion-webui-docker/releases/download/2.1.0/xformers-0.0.14.dev0-cp310-cp310-linux_x86_64.whl'

FROM quay.io/fedora/fedora:36

# this will depend on your gpu card
# Use f35 repo. There is also a f36 repo that is known not to work.
RUN dnf -y install 'dnf-command(config-manager)' \
    && dnf -y config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora35/x86_64/cuda-fedora35.repo
RUN dnf -y install nvidia-driver-cuda

RUN dnf -y install python3-pip
ENV PIP_PREFER_BINARY=1 PIP_NO_CACHE_DIR=1
RUN pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113
RUN dnf -y install dejavu-* rsync git jq moreutils && dnf clean all

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git \
  && cd stable-diffusion-webui && git reset --hard d885a4a57b72152745ca76192ef1bdda29e6461d \
  && pip install -r requirements_versions.txt && cd ../

COPY --from=xformers /wheel.whl /xformers-0.0.14.dev0-cp310-cp310-linux_x86_64.whl
RUN pip install /xformers-0.0.14.dev0-cp310-cp310-linux_x86_64.whl && rm -f /xformers-0.0.14.dev0-cp310-cp310-linux_x86_64.whl

ENV ROOT=/stable-diffusion-webui

COPY --from=download /projects/ ${ROOT}
RUN mkdir ${ROOT}/interrogate && cp ${ROOT}/clip-interrogator/data/* ${ROOT}/interrogate
RUN pip install --prefer-binary --no-cache-dir -r ${ROOT}/CodeFormer/requirements.txt

ARG DEEPDANBOORU="0"
RUN [[ "${DEEPDANBOORU:-0}" == "0" ]] && : || pip install tensorflow-cpu==2.10 tensorflow-io==0.27.0 git+https://github.com/KichangKim/DeepDanbooru.git@edf73df4cdaeea2cf00e9ac08bd8a9026b7a7b26#egg=deepdanbooru

# Note: don't update the sha of previous versions because the install will take forever
# instead, update the repo state in a later step

ARG SHA=804d9fb83d0c63ca3acd36378707ce47b8f12599

WORKDIR stable-diffusion-webui
RUN git fetch
RUN git reset --hard ${SHA}
RUN pip install -r requirements_versions.txt

RUN pip install opencv-python-headless \
  git+https://github.com/TencentARC/GFPGAN.git@8d2447a2d918f8eba5a4a01463fd48e45126a379 \
  git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 \
  pyngrok

COPY entrypoint.sh info.py config.json /opt

RUN python3 /opt/info.py ${ROOT}/modules/ui.py
RUN mv  ${ROOT}/style.css ${ROOT}/user.css
RUN sed -i 's/os.rename(tmpdir, target_dir)/shutil.move(tmpdir,target_dir)/' ${ROOT}/modules/ui_extensions.py

WORKDIR ${ROOT}/stable-diffusion
ENV CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/opt/entrypoint.sh"]
# run, -u to not buffer stdout / stderr
CMD python3 -u /stable-diffusion-webui/webui.py --listen --port 7860 --ckpt-dir ${ROOT}/models/Stable-diffusion ${CLI_ARGS}

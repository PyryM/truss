sudo apt-get update -qq -y
sudo apt-get install -qq -y libtinfo-dev
mkdir _deps
cd _deps
curl -o terra.tar.xz -L https://github.com/terralang/terra/releases/download/release-1.0.5/terra-Linux-x86_64-f85f743.tar.xz
tar -xvf terra.tar.xz
git clone https://github.com/pyrym/trussfs
cd trussfs
cargo build --release
cd ..
cd ..
mkdir include/terra
cp -r _deps/terra-Linux-x86_64-f85f743/include/* include/
cp _deps/terra-Linux-x86_64-f85f743/lib/* lib/
cp _deps/terra-Linux-x86_64-f85f743/bin/* bin/
cp bin/terra .
cp _deps/trussfs/target/release/*.so lib/
./terra src/build/selfbuild.t
./truss dev/downloadlibs.t
./truss dev/buildshaders.t

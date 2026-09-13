# VAMP: https://github.com/KavrakiLab/vamp
# uv pip install vamp-planner

# OMPL: https://ompl.kavrakilab.org/installation.html
# sudo apt install libompl-dev ompl-demos

~/CMAKE/3.30.0/bin/cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=ON -DGEODEX_ROBOTS=ON -DGEODEX_PINOCCHIO=ON -DBUILD_OMPL_EXAMPLES=ON -DGEODEX_VAMP=ON 
~/CMAKE/3.30.0/bin/cmake --build build

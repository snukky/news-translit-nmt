# Neural Machine Translation Techniques for Named Entity Transliteration

This repository contains training scripts and instructions how to reproduce our systems submitted to
the NEWS 2018 Shared Task on Transliteration of Named Entities, and described in R. Grundkiewicz, K.
Heafield: [_Neural Machine Translation Techniques for Named Entity
Transliteration_](http://www.aclweb.org/anthology/W18-2413), NEWS 2018, ACL 2018

Citation:

    @InProceedings{grundkiewicz-heafield:2018:NEWS2018,
      author    = {Grundkiewicz, Roman  and  Heafield, Kenneth},
      title     = {Neural Machine Translation Techniques for Named Entity Transliteration},
      booktitle = {Proceedings of the Seventh Named Entities Workshop},
      month     = {July},
      year      = {2018},
      address   = {Melbourne, Australia},
      publisher = {Association for Computational Linguistics},
      pages     = {89--94},
      url       = {http://www.aclweb.org/anthology/W18-2413}
    }


## Training

1. Download and compile Marian in `tools/marian-dev`:

        cd tools
        git clone https://github.com/marian-nmt/marian-dev
        mkdir marian-dev/build
        cd marian-dev/build
        cmake .. -DCMAKE_BUILD_TYPE=Release
        make -j8
        cd ../../..

   If needed, please refer to the official Marian documentation at https://marian-nmt.github.io/docs

2. Download data sets 01-04 from http://workshop.colips.org/news2018/dataset.html and unzip them
   into `datasets`.

3. Prepare training and development data:

        cd experiments
        bash prepare-data.sh

4. Train baseline systems specifying GPU device(s) and one or more language directions, e.g.:

        bash train.sh '0 1' EnVi EnCh ChEn

    Each system will be an ensemble of 4 deep RNN models rescored by 2 right-left models.

    The evaluation scores can be collected by running:

        bash show-results.sh

5. A text file can be translated using the `translate.sh` script, for example:

        head data/EnVi.dev.src | ./translate.sh EnVi file.tmp 0 > file.out

6. Prepare synthetic data with the back-translation or forward-translation method:

        bash prepare-synthetic-data.sh

   The systems can be re-trained with additional data by replacing original folders and re-running
   the training script, e.g.:

        mv data data.original
        mv synthetic data
        mv models models.baseline
        bash train.sh '0 1' EnVi EnCh ChEn
        bash show-results.sh

    For the EnVi system, this should display results similar to the following:

                                                ACC     Fscore  MRR     MAPref
        models.baseline/EnVi.1                  0.4680  0.8742  0.5582  0.4680
        models.baseline/EnVi.2                  0.4900  0.8806  0.5693  0.4900
        models.baseline/EnVi.3                  0.4580  0.8744  0.5521  0.4580
        models.baseline/EnVi.4                  0.4600  0.8692  0.5543  0.4600
        models.baseline/EnVi.ens                0.4740  0.8783  0.5649  0.4740
        models.baseline/EnVi.ens.r2l            0.4800  0.8815  0.5767  0.4800
        models.baseline/EnVi.ens.r2l.rescore    0.4880  0.8830  0.5777  0.4880
        models.baseline/EnVi.r2l.1              0.4520  0.8710  0.5548  0.4520
        models.baseline/EnVi.r2l.2              0.4860  0.8759  0.5791  0.4860
        models/EnVi.1                           0.4980  0.8856  0.5838  0.4980
        models/EnVi.2                           0.4860  0.8833  0.5771  0.4860
        models/EnVi.3                           0.4860  0.8836  0.5785  0.4860
        models/EnVi.4                           0.4980  0.8854  0.5833  0.4980
        models/EnVi.ens                         0.5000  0.8865  0.5859  0.5000
        models/EnVi.ens.r2l                     0.4820  0.8858  0.5817  0.4820
        models/EnVi.ens.r2l.rescore             0.5020  0.8884  0.5905  0.5020
        models/EnVi.r2l.1                       0.4800  0.8843  0.5789  0.4800
        models/EnVi.r2l.2                       0.4920  0.8876  0.5860  0.4920

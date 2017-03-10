from collections import defaultdict
from operator import itemgetter
import sys

wordcount_dict = defaultdict(int)

for line in sys.stdin:
    word, count = line.strip().split('\t')
    wordcount_dict[word] += int(count)

for word, count in sorted(wordcount_dict.items(), key=itemgetter(0)):
    print '{0}\t{1}'.format("\t".join(word.split("_")), count)


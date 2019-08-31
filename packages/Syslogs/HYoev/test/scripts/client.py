import logging
import logging.handlers

# formatter = logging.Formatter(fmt='%(asctime)s %(levelname)s:%(message)s')
formatter = logging.Formatter(fmt='%(name)s %(levelname)s:%(message)s')

logger = logging.getLogger('MyLogger')
logger.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address = ('localhost', 8080))
handler.setFormatter(formatter)

logger.addHandler(handler)

logger.info("I'm nobody! Who are you?\n")
logger.debug("Are you nobody, too?\n")
logger.info("Then there's a pair of us -- don't tell!\n")
logger.warn("They'd advertise -- you know!\n")
logger.info("\n")
logger.info("How dreary to be somebody!\n")
logger.info("How public like a frog\n")
logger.info("To tell one's name the livelong day\n")
logger.info("To an admiring bog!\n")

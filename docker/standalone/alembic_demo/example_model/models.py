from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.ext.declarative import AbstractConcreteBase
import sqlalchemy as sa

class Base(DeclarativeBase):
    pass


class Persona( Base ):
    __tablename__ = 'persona'

    pk = sa.Column( sa.Integer,
                    sa.Identity(start = 1, cycle = True ),
                    primary_key = True )
    nome           = sa.Column( sa.String( 50 ) )
    cognome        = sa.Column( sa.String( 50 ) )
    codice_fiscale = sa.Column( sa.String( 16 ), nullable = False )

    eta = sa.Column( sa.Integer )

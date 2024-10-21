"""Creazione della tabella PERSONA

Revision ID: 3d7495ef8b44
Revises: 
Create Date: 2024-07-24 12:46:48.098998

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3d7495ef8b44'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    CREATE TABLE persona(
    pk integer generated always as identity
    , nome text
    , cognome text
    , codice_fiscale varchar(16) NOT NULL
    );
    """
    op.create_table(
        'persona',
        sa.Column( 'pk',
                   sa.Integer,
                   sa.Identity(start = 1, cycle = True ),
                   primary_key = True ),
        sa.Column( 'nome', sa.String( 50 ) ),
        sa.Column( 'cognome', sa.String( 50 ) ),
        sa.Column( 'codice_fiscale', sa.String( 16 ), nullable = False )
        )


def downgrade() -> None:
    op.drop_table( 'persona' )

"""Aggiunta di colonna data nascita, sesso, ecc.

Revision ID: 830e787ba6be
Revises: a002f97dc017
Create Date: 2024-07-24 13:13:53.808288

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '830e787ba6be'
down_revision: Union[str, None] = 'a002f97dc017'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column( 'persona', sa.Column( 'data_nascita', sa.Date, nullable = True ) )
    op.add_column( 'persona',
                   sa.Column( 'sesso', sa.String( 1 ), server_default = 'M',
                              nullable = False ) )
    op.create_check_constraint( 'persona_sesso_valid_values',
                                'persona',
                                "sesso IN ( 'M', 'F' )" )



def downgrade() -> None:
    op.drop_column( 'persona', 'data_nascita' )
    op.drop_column( 'persona', 'sesso' )
